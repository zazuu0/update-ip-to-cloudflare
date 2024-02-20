#!/bin/bash

# Interfaces
wan1="enp6s18"
wan2="enp6s18"

# Read the bearer token from the configuration file for Cloudflare API
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bearer_token=$(grep ^BEARER_TOKEN "$script_dir/update_public_ip.conf" | cut -d '=' -f2)
accountid=$(grep ^ACCOUNT_ID "$script_dir/update_public_ip.conf" | cut -d '=' -f2)
wan1_groupid=$(grep ^WAN1_GROUP_ID "$script_dir/update_public_ip.conf" | cut -d '=' -f2)
wan2_groupid=$(grep ^WAN2_GROUP_ID "$script_dir/update_public_ip.conf" | cut -d '=' -f2)

# Cloudflare API URLs
cloudflare_api_url_wan1="https://api.cloudflare.com/client/v4/accounts/$accountid/access/groups/$wan1_groupid"
cloudflare_api_url_wan2="https://api.cloudflare.com/client/v4/accounts/$accountid/access/groups/$wan2_groupid"



# Function to check if interface exists
check_interface() {
    local interface="$1"
    # Check if the interface exists
    if ip link show "$interface" >/dev/null 2>&1; then
        return 0  # Interface exists
    else
        return 1  # Interface does not exist
    fi
}

# Function to get IP address from Cloudflare API
get_cloudflare_ip() {
    local interface="$1"
    local cloudflare_api_url="$2"
    # Retrieve the IP address associated with the specified interface from Cloudflare API
    local cloudflare_ip=$(curl --interface "$interface" -s -H "Authorization: Bearer $bearer_token" "$cloudflare_api_url" | jq -r '.result.include[0].ip.ip')
    echo "$cloudflare_ip"
}

# Function to get public IP address
get_public_ip() {
    local interface="$1"
    # Retrieve the public IP address of the specified interface
    local public_ip=$(curl --interface "$interface" -s https://api.ipify.org?format=json | jq -r '.ip')
    echo "${public_ip}/32"  # Append "/32" to the IP address
}

# Function to update IP address in Cloudflare API
update_cloudflare_ip() {
    local interface="$1"
    local new_ip="$2"
    local cloudflare_api_url="$3"
    # Update the IP address associated with the specified interface in Cloudflare API
    local update_result=$(curl --interface "$interface" -s -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $bearer_token" -d "{\"include\": [{\"ip\": {\"ip\": \"$new_ip\"}}]}" "$cloudflare_api_url")
    echo "$update_result"
}

# Interface wan2
if check_interface "$wan1"; then
    echo "WAN 1 Interface $wan1 exists."
    # Retrieve the IP address from Cloudflare API
    cloudflare_ip=$(get_cloudflare_ip "$wan1" "$cloudflare_api_url_wan1")
    if [ -n "$cloudflare_ip" ]; then
        echo "IP Address from Cloudflare API for $wan1: $cloudflare_ip"
        # Retrieve the current public IP address
        current_ip=$(get_public_ip "$wan1")
        if [ -n "$current_ip" ]; then
            echo "Current Public IP Address for $wan1: $current_ip"
            # Compare the current public IP with the IP from Cloudflare API
            if [ "$current_ip" != "$cloudflare_ip" ]; then
                echo "Updating IP address in Cloudflare for $wan1..."
                # Update the IP address in Cloudflare API
                update_result=$(update_cloudflare_ip "$wan1" "$current_ip" "$cloudflare_api_url_wan1")
                echo "Update result: $update_result"
            else
                echo "Your public IP address for $wan1 matches the Cloudflare IP."
            fi
        else
            echo "Failed to retrieve current public IP address for $wan1."
        fi
    else
        echo "Failed to retrieve IP address from Cloudflare API for $wan1."
    fi
else
    echo "Interface $wan1 does not exist."
fi


# Interface wan2
if check_interface "$wan2"; then
    echo "WAN 2 Interface $wan2 exists."
    # Retrieve the IP address from Cloudflare API
    cloudflare_ip=$(get_cloudflare_ip "$wan2" "$cloudflare_api_url_wan2")
    if [ -n "$cloudflare_ip" ]; then
        echo "IP Address from Cloudflare API for $wan2: $cloudflare_ip"
        # Retrieve the current public IP address
        current_ip=$(get_public_ip "$wan2")
        if [ -n "$current_ip" ]; then
            echo "Current Public IP Address for $wan2: $current_ip"
            # Compare the current public IP with the IP from Cloudflare API
            if [ "$current_ip" != "$cloudflare_ip" ]; then
                echo "Updating IP address in Cloudflare for $wan2..."
                # Update the IP address in Cloudflare API
                update_result=$(update_cloudflare_ip "$wan2" "$current_ip" "$cloudflare_api_url_wan2")
                echo "Update result: $update_result"
            else
                echo "Your public IP address for $wan2 matches the Cloudflare IP."
            fi
        else
            echo "Failed to retrieve current public IP address for $wan2."
        fi
    else
        echo "Failed to retrieve IP address from Cloudflare API for $wan2."
    fi
else
    echo "WAN 2 Interface $wan2 does not exist."
fi
