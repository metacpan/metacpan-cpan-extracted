# Options

| Code | Name               | Length                | Note                                                                                                           |
|------|--------------------|-----------------------|----------------------------------------------------------------------------------------------------------------|
| 0    | Pad                | 0 octets              | Can be used to pad other options so that they are aligned to the word boundary; is not followed by length byte |
| 1    | Subnet mask        | 4 octets              | Must be sent before the router option (option 3) if both are included                                          |
| 2    | Time offset        | 4 octets              |                                                                                                                |
| 3    | Router             | Multiples of 4 octets | Available routers, should be listed in order of preference                                                     |
| 4    | Time server        | Multiples of 4 octets | Available time servers to synchronise with, should be listed in order of preference                            |
| 5    | Name server        | Multiples of 4 octets | Available IEN 116 name servers, should be listed in order of preference                                        |
| 6    | Domain name server | Multiples of 4 octets | Available DNS servers, should be listed in order of preference                                                 |
| 7    | Log server         | Multiples of 4 octets | Available log servers, should be listed in order of preference.                                                |
| 8    | Cookie server      | Multiples of 4 octets | Cookie in this case means "fortune cookie"                                                                     |
| 9    | LPR Server         | Multiples of 4 octets |                                                                                                                |
| 10   | Impress server     | Multiples of 4 octets |                                                                                                                |
| 11   | Res loc svr        | Multiples of 4 octets |                                                                                                                |
| 12   | Host name          | Minimum of 1 octet    |                                                                                                                |
| 13   | Boot file   size   | 2 octets              | Length of the boot image in 4KiB blocks                                                                        |
| 14   | Merit dump file    | Minimum of 1 octet    | Path where crash dumps should be stored                                                                        |
| 15   | Domain name        | Minimum of 1 octet    |                                                                                                                |
| 16   | Swap server        | 4 octets              |                                                                                                                |
| 17   | Root path          | Minimum of 1 octet    |                                                                                                                |
| 18   | Extensions path    | Minimum of 1 octet    |                                                                                                                |
| 255  | End                | 0 octets              | Used to mark the end of the vendor option field                                                                |

# IP layer parameters per host

| Code | Name                                    | Length                | Note |
|------|-----------------------------------------|-----------------------|------|
| 19   | IP forwarding enable/disable            | 1 octet               |      |
| 20   | Non-local source routing enable/disable | 1 octet               |      |
| 21   | Policy filter                           | Multiples of 8 octets |      |
| 22   | Maximum datagram reassembly size        | 2 octets              |      |
| 23   | Default IP time-to-live                 | 1 octet               |      |
| 24   | Path MTU aging timeout                  | 4 octets              |      |
| 25   | Path MTU plateau table                  | Multiples of 2 octets |      |

# IP Layer Parameters per Interface

| Code | Name                        | Length                | Note                               |
|------|-----------------------------|-----------------------|------------------------------------|
| 26   | Interface MTU               | 2 octets              |                                    |
| 27   | All subnets are local       | 1 octet               |                                    |
| 28   | Broadcast address           | 4 octets              |                                    |
| 29   | Perform mask discovery      | 1 octet               |                                    |
| 30   | Mask supplier               | 1 octet               |                                    |
| 31   | Perform router discovery    | 1 octet               |                                    |
| 32   | Router solicitation address | 4 octets              |                                    |
| 33   | Static route                | Multiples of 8 octets | A list of destination/router pairs |

# Link layer parameters per interface

| Code | Name                         | Length   | Note |
|------|------------------------------|----------|------|
| 34   | Trailer encapsulation option | 1 octet  |      |
| 35   | ARP cache timeout            | 4 octets |      |
| 36   | Ethernet encapsulation       | 1 octet  |      |

# TCP parameters

| Code | Name                   | Length   | Note |
|------|------------------------|----------|------|
| 37   | TCP default TTL        | 1 octet  |      |
| 38   | TCP keepalive interval | 4 octets |      |
| 39   | TCP keepalive garbage  | 1 octet  |      |

# Application and service parameters

| Code | Name                                             | Length                | Note |
|------|--------------------------------------------------|-----------------------|------|
| 40   | Network information service domain               | Minimum of 1 octet    |      |
| 41   | Network information servers                      | Multiples of 4 octets |      |
| 42   | Network Time Protocol (NTP) servers              | Multiples of 4 octets |      |
| 43   | Vendor-specific information                      | Minimum of 1 octets   |      |
| 44   | NetBIOS over TCP/IP name server                  | Multiples of 4 octets |      |
| 45   | NetBIOS over TCP/IP datagram Distribution Server | Multiples of 4 octets |      |
| 46   | NetBIOS over TCP/IP node type                    | 1 octet               |      |
| 47   | NetBIOS over TCP/IP scope                        | Minimum of 1 octet    |      |
| 48   | X Window System font server                      | Multiples of 4 octets |      |
| 49   | X Window System display manager                  | Multiples of 4 octets |      |
| 64   | Network Information Service+ domain              | Minimum of 1 octet    |      |
| 65   | Network Information Service+ servers             | Multiples of 4 octets |      |
| 68   | Mobile IP home agent                             | Multiples of 4 octets |      |
| 69   | Simple Mail Transfer Protocol (SMTP) server      | Multiples of 4 octets |      |
| 70   | Post Office Protocol (POP3) server               | Multiples of 4 octets |      |
| 71   | Network News Transfer Protocol (NNTP) server     | Multiples of 4 octets |      |
| 72   | Default World Wide Web (WWW) server              | Multiples of 4 octets |      |
| 73   | Default Finger protocol server                   | Multiples of 4 octets |      |
| 74   | Default Internet Relay Chat (IRC) server         | Multiples of 4 octets |      |
| 75   | StreetTalk server                                | Multiples of 4 octets |      |
| 76   | StreetTalk Directory Assistance (STDA) server    | Multiples of 4 octets |      |

# DHCP extensions

| Code | Name                      | Length              | Note |
|------|---------------------------|---------------------|------|
| 50   | Requested IP address      | 4 octets            |      |
| 51   | lease time                | lease time 4 octets |      |
| 52   | Option overload           | 1 octet             |      |
| 53   | DHCP message type         | 1 octet             |      |
| 54   | Server identifier         | 4 octets            |      |
| 55   | Parameter request list    | Minimum of 1 octet  |      |
| 56   | Message                   | Minimum of 1 octet  |      |
| 57   | Maximum DHCP message size | 2 octets            |      |
| 58   | Renewal (T1) time value   | 4 octets            |      |
| 59   | Rebinding (T2) time value | 4 octets            |      |
| 60   | Vendor class identifier   | Minimum of 1 octet  |      |
| 61   | Client-identifier         | Minimum of 2 octets |      |
| 66   | TFTP server name          | Minimum of 1 octet  |      |
| 67   | Bootfile name             | Minimum of 1 octet  |      |

# Misc Other

| Code | Name                                   | Length                                    | Note               |
|------|----------------------------------------|-------------------------------------------|--------------------|
| 82   | Relay agent information                | Minimum of 2 octets                       | RFC 3046           |
| 85   | Novell Directory Service (NDS) servers | Minimum of 4 octets, multiple of 4 octets | RFC 2241:Section 2 |
| 86   | NDS tree name                          | Variable                                  | RFC 2241:Section 3 |
| 87   | NDS context                            | Variable                                  | RFC 2241:Section 4 |
| 100  | Time zone, POSIX style                 | Variable                                  | RFC 4833           |
| 101  | Time zone, tz database style           | Variable                                  | RFC 4833           |
| 119  | Domain search                          | Variable                                  | RFC 3397           |
| 121  | Classless static route                 | Variable                                  | RFC 3442           |

# Windows Default Supported

* 1-49
* 51
* 58-60
* 64-76
* 121

The following are non-standard additions, but appear to be the be able to be ignored.

```
Dhcp Server \\winboot Add Optiondef 1 "Microsoft Disable Netbios Option " DWORD 0 vendor="Microsoft Options" comment="Option for enabling or disabling Netbios for Microsoft Windows 2000 Clients" 1
Dhcp Server \\winboot Add Optiondef 2 "Microsoft Release DHCP Lease On Shutdown Option" DWORD 0 vendor="Microsoft Options" comment="Option for enabling or disabling Windows 2000 Clients to release DHCP lease on shutdown" 1
Dhcp Server \\winboot Add Optiondef 3 "Microsoft Default Router Metric Base" DWORD 0 vendor="Microsoft Options" comment="Default Router Base Metrics for Microsoft Windows 2000 Clients" 1
Dhcp Server \\winboot Add Optiondef 1 "Microsoft Disable Netbios Option " DWORD 0 vendor="Microsoft Windows 2000 Options" comment="Option for enabling or disabling Netbios for Microsoft Windows 2000 Clients" 1
Dhcp Server \\winboot Add Optiondef 2 "Microsoft Release DHCP Lease On Shutdown Option" DWORD 0 vendor="Microsoft Windows 2000 Options" comment="Option for enabling or disabling Windows 2000 Clients to release DHCP lease on shutdown" 1
Dhcp Server \\winboot Add Optiondef 3 "Microsoft Default Router Metric Base" DWORD 0 vendor="Microsoft Windows 2000 Options" comment="Default Router Base Metrics for Microsoft Windows 2000 Clients" 0
```

The ones we care about are as below.

```
Dhcp Server \\winboot Add Optiondef 121 "Classless Static Routes" BINARY 0 comment="Destination, mask and router IP addresses in priority order"
Dhcp Server \\winboot Add Optiondef 1 "Subnet Mask" IPADDRESS 0 comment="Subnet mask in network byte order" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 2 "Time Offset" DWORD 0 comment="UCT offset in seconds" 0
Dhcp Server \\winboot Add Optiondef 3 "Router" IPADDRESS 1 comment="Array of router addresses ordered by preference" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 4 "Time Server" IPADDRESS 1 comment="Array of time server addresses, by preference" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 5 "Name Servers" IPADDRESS 1 comment="Array of name servers [IEN 116], by preference" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 6 "DNS Servers" IPADDRESS 1 comment="Array of router addresses ordered by preference" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 7 "Log Servers" IPADDRESS 1 comment="Array of MIT_LCS UDP log servers on subnet" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 8 "Cookie Servers" IPADDRESS 1 comment="Array of cookie servers, RFC 865" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 9 "LPR Servers" IPADDRESS 1 comment="Array of RFC 1179 servers, by preference" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 10 "Impress Servers" IPADDRESS 1 comment="Array of Imagen Impress Servers" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 11 "Resource Location Servers" IPADDRESS 1 comment="Array of RFC 887 ResLoc Servers on subnet, by preference" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 12 "Host Name" STRING 0 comment="Host name for client, RFC 1035 character set" ""
Dhcp Server \\winboot Add Optiondef 13 "Boot File Size" WORD 0 comment="Size of boot image file in 512-octet blocks" 0
Dhcp Server \\winboot Add Optiondef 14 "Merit Dump File" STRING 0 comment="Path name for crash dump file" ""
Dhcp Server \\winboot Add Optiondef 15 "DNS Domain Name" STRING 0 comment="DNS Domain name for client resolutions" ""
Dhcp Server \\winboot Add Optiondef 16 "Swap Server" IPADDRESS 0 comment="Address of client's swap server" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 17 "Root Path" STRING 0 comment="Path name for client's root disk, char set NVT ASCII" ""
Dhcp Server \\winboot Add Optiondef 18 "Extensions Path" STRING 0 comment="tftp file for option extensions" ""
Dhcp Server \\winboot Add Optiondef 19 "IP Layer Forwarding" BYTE 0 comment="Disable/enable IP packet forwarding on this client" 0
Dhcp Server \\winboot Add Optiondef 20 "Nonlocal Source Routing" BYTE 0 comment="Disable/enable nonlocal datagrams" 0
Dhcp Server \\winboot Add Optiondef 21 "Policy Filter Masks" IPADDRESS 1 comment="Destination/mask IP address pairs to filter source routes" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 22 "Max DG Reassembly Size" WORD 0 comment="Maximum size datagram for reassembly by client; max 576" 0
Dhcp Server \\winboot Add Optiondef 23 "Default IP Time-to-live" BYTE 0 comment="Default TTL for client's use on outgoing DGs" 0
Dhcp Server \\winboot Add Optiondef 24 "Path MTU Aging Timeout" DWORD 0 comment="Timeout in seconds for aging Path MTU values; RFC 1191" 0
Dhcp Server \\winboot Add Optiondef 25 "Path MTU Plateau Table" WORD 1 comment="MTU discovery sizes, sorted by size, all >= 68" 0
Dhcp Server \\winboot Add Optiondef 26 "MTU Option" WORD 0 comment="MTU discovery size, >= 68" 0
Dhcp Server \\winboot Add Optiondef 27 "All subnets are local" BYTE 0 comment="The client assumes that all subnets are local" 0
Dhcp Server \\winboot Add Optiondef 28 "Broadcast Address" IPADDRESS 0 comment="Broadcast address" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 29 "Perform Mask Discovery" BYTE 0 comment="The client should use ICMP for subnet mask discovery." 0
Dhcp Server \\winboot Add Optiondef 30 "Mask Supplier Option" BYTE 0 comment="The client should respond to subnet mask requests via ICMP." 0
Dhcp Server \\winboot Add Optiondef 31 "Perform Router Discovery" BYTE 0 comment="The client should solicit routers using RFC 1256." 0
Dhcp Server \\winboot Add Optiondef 32 "Router Solicitation Address" IPADDRESS 0 comment="Address to use for router solicitation" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 33 "Static Route Option" IPADDRESS 1 comment="Destination/router address pairs, in priority order" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 34 "Trailer Encapsulation" BYTE 0 comment="The client should negotiate use of trailers (RFC 983)." 0
Dhcp Server \\winboot Add Optiondef 35 "ARP Cache Timeout" DWORD 0 comment="Timeout in seconds for ARP cache entries" 0
Dhcp Server \\winboot Add Optiondef 36 "Ethernet Encapsulation" BYTE 0 comment="0=>client should use ENet V2; 1=> IEEE 802.3" 0
Dhcp Server \\winboot Add Optiondef 37 "TCP Default Time-to-live" BYTE 0 comment="TTL that client uses when sending TCP segments" 0
Dhcp Server \\winboot Add Optiondef 38 "Keepalive Interval" DWORD 0 comment="Keepalive timeout in seconds" 0
Dhcp Server \\winboot Add Optiondef 39 "Keepalive Garbage" BYTE 0 comment="Send garbage octet" 0
Dhcp Server \\winboot Add Optiondef 40 "NIS Domain Name" STRING 0 comment="Name of Network Information Service domain" ""
Dhcp Server \\winboot Add Optiondef 41 "NIS Servers" IPADDRESS 1 comment="Addresses of NIS servers on client's subnet" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 42 "NTP Servers" IPADDRESS 1 comment="Addresses of Network Time Protocol servers" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 43 "Vendor Specific Info" BINARY 0 comment="Embedded vendor-specific options"
Dhcp Server \\winboot Add Optiondef 44 "WINS/NBNS Servers" IPADDRESS 1 comment="NBNS Address(es) in priority order" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 45 "NetBIOS over TCP/IP NBDD" IPADDRESS 1 comment="NetBIOS over TCP/IP NBDD address(es) in priority order" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 46 "WINS/NBT Node Type" BYTE 0 comment="0x1 = B-node, 0x2 = P-node, 0x4 = M-node, 0x8 = H-node" 0
Dhcp Server \\winboot Add Optiondef 47 "NetBIOS Scope ID" STRING 0 comment="NetBIOS over TCP/IP Scope ID" ""
Dhcp Server \\winboot Add Optiondef 48 "X Window System Font" IPADDRESS 1 comment="Array of X Windows font servers" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 49 "X Window System Display" IPADDRESS 1 comment="Array of X Windows Display Mgr servers" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 51 "Lease" DWORD 0 comment="Client IP address lease time in seconds" 0
Dhcp Server \\winboot Add Optiondef 58 "Renewal (T1) Time Value" DWORD 0 comment="Time between addr assignment to RENEWING state" 0
Dhcp Server \\winboot Add Optiondef 59 "Rebinding (T2) Time Value" DWORD 0 comment="Time from addr assignment to REBINDING state" 0
Dhcp Server \\winboot Add Optiondef 64 "NIS+ Domain Name" STRING 0 comment="The name of the client's NIS+ domain." ""
Dhcp Server \\winboot Add Optiondef 65 "NIS+ Servers" IPADDRESS 1 comment="A list of IP addresses indicating NIS+ servers" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 66 "Boot Server Host Name" STRING 0 comment="TFTP boot server host name" ""
Dhcp Server \\winboot Add Optiondef 67 "Bootfile Name" STRING 0 comment="Bootfile Name" ""
Dhcp Server \\winboot Add Optiondef 68 "Mobile IP Home Agents" IPADDRESS 1 comment="Mobile IP home agents in priority order" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 69 "Simple Mail Transport Protocol (SMTP) Servers" IPADDRESS 1 comment="List of SMTP servers available to the client" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 70 "Post Office Protocol (POP3) Servers" IPADDRESS 1 comment="List of POP3 servers available to the client" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 71 "Network News Transport Protocol (NNTP) Servers" IPADDRESS 1 comment="List of NNTP servers available to the client" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 72 "World Wide Web (WWW) Servers" IPADDRESS 1 comment="List of WWW servers available to the client" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 73 "Finger Servers" IPADDRESS 1 comment="List of Finger servers available to the client" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 74 "Internet Relay Chat (IRC) Servers" IPADDRESS 1 comment="List of IRC servers available to the client" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 75 "StreetTalk Servers" IPADDRESS 1 comment="List of StreetTalk servers available to the client" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 76 "StreetTalk Directory Assistance (STDA) Servers" IPADDRESS 1 comment="List of STDA servers available to the client" 0.0.0.0
Dhcp Server \\winboot Add Optiondef 60 "PXEClient" STRING 0 comment="PXE Support" "PXEClient"
```

# Defaults In Windows

Below is a example how defaults will appear.

```
Dhcp Server \\winboot set optionvalue 15 STRING "foo.bar"
Dhcp Server \\winboot set optionvalue 6 IPADDRESS "1.2.3.4" "5.6.7.8"
Dhcp Server \\winboot set optionvalue 66 STRING "1.2.3.4"
Dhcp Server \\winboot set optionvalue 67 STRING "linux"
Dhcp Server \\winboot set optionvalue 60 STRING "PXEClient"
```

# Options Code To ISC-DHCPD Mapping

| Code | ISC-DHCPD                                                               | Note                                         |
|------|-------------------------------------------------------------------------|----------------------------------------------|
| 0    | option subnet-mask ip-address;                                          |                                              |
| 1    | option time-offset int32;                                               |                                              |
| 3    | option routers ip-address [, ip-address... ];                           |                                              |
| 4    | option time-servers ip-address [, ip-address... ];                      |                                              |
| 5    | option ien116-name-servers ip-address [, ip-address... ];               |                                              |
| 6    | option domain-name-servers ip-address [, ip-address... ];               |                                              |
| 7    | option log-servers ip-address [, ip-address... ];                       |                                              |
| 8    | option cookie-servers ip-address [, ip-address... ];                    |                                              |
| 9    | option lpr-servers ip-address [, ip-address... ];                       |                                              |
| 10   | option impress-servers ip-address [, ip-address... ];                   |                                              |
| 11   | option resource-location-servers ip-address                             |                                              |
| 12   | option host-name string;                                                |                                              |
| 13   | option boot-size uint16;                                                |                                              |
| 14   | option merit-dump text;                                                 |                                              |
| 15   | option domain-name text;                                                |                                              |
| 16   | option swap-server ip-address;                                          |                                              |
| 17   | option root-path text;                                                  |                                              |
| 18   | option extensions-path text;                                            |                                              |
| 19   | option ip-forwarding flag;                                              |                                              |
| 20   | option non-local-source-routing flag;                                   |                                              |
| 21   | option policy-filter ip-address ip-address[, ip-address ip-address...]; |                                              |
| 22   | option max-dgram-reassembly uint16;                                     |                                              |
| 23   | option default-ip-ttl uint8;                                            |                                              |
| 24   | option path-mtu-aging-timeout uint32;                                   |                                              |
| 25   | option path-mtu-plateau-table uint16 [, uint16... ];                    |                                              |
| 26   | option interface-mtu uint16;                                            |                                              |
| 27   | option all-subnets-local flag;                                          |                                              |
| 28   | option broadcast-address ip-address;                                    |                                              |
| 29   | option perform-mask-discovery flag;                                     |                                              |
| 30   | option mask-supplier flag;                                              |                                              |
| 31   | option router-discovery flag;                                           |                                              |
| 32   | option router-solicitation-address ip-address;                          |                                              |
| 33   | option static-routes ip-address ip-address[, ip-address ip-address...]; |                                              |
| 34   | option trailer-encapsulation flag;                                      |                                              |
| 35   | option arp-cache-timeout uint32;                                        |                                              |
| 36   | option ieee802-3-encapsulation flag;                                    |                                              |
| 37   | option default-tcp-ttl uint8;                                           |                                              |
| 38   | option tcp-keepalive-interval uint32;                                   |                                              |
| 39   | option tcp-keepalive-garbage flag;                                      |                                              |
| 40   | option nis-domain text;                                                 |                                              |
| 41   | option nis-servers ip-address [, ip-address... ];                       |                                              |
| 42   | option ntp-servers ip-address [, ip-address... ];                       |                                              |
| 43   |                                                                         | Seems to be split up among multiple options. |
| 44   | option netbios-name-servers ip-address [, ip-address...];               |                                              |
| 45   | option netbios-dd-server ip-address [, ip-address... ];                 |                                              |
| 46   | option netbios-node-type uint8;                                         |                                              |
| 47   | option netbios-scope string;                                            |                                              |
| 48   | option font-servers ip-address [, ip-address... ];                      |                                              |
| 49   | option x-display-manager ip-address [, ip-address... ];                 |                                              |
| 50   | option dhcp-requested-address ip-address;                               | Not user setable                             |
| 51   | option dhcp-lease-time uint32;                                          |                                              |
| 52   | option dhcp-option-overload uint8;                                      |                                              |
| 53   | option dhcp-message-type uint8;                                         |                                              |
| 54   | option dhcp-server-identifier ip-address;                               |                                              |
| 55   | option dhcp-parameter-request-list uint8 [, uint8... ];                 |                                              |
| 56   | option dhcp-message text;                                               | Not user setable                             |
| 57   | option dhcp-max-message-size uint16;                                    |                                              |
| 58   | option dhcp-renewal-time uint32;                                        |                                              |
| 59   | option dhcp-rebinding-time uint32;                                      |                                              |
| 60   | Vendor class identifier                                                 |                                              |
| 64   | option nisplus-domain text;                                             |                                              |
| 65   | option nisplus-servers ip-address [, ip-address... ];                   |                                              |
| 66   | option tftp-server-name text;                                           |                                              |
| 67   | option bootfile-name text;                                              |                                              |
| 68   | option mobile-ip-home-agent ip-address [, ip-address... ];              |                                              |
| 69   | option smtp-server ip-address [, ip-address... ];                       |                                              |
| 70   | option pop-server ip-address [, ip-address... ];                        |                                              |
| 71   | option nntp-server ip-address [, ip-address... ];                       |                                              |
| 72   | option www-server ip-address [, ip-address... ];                        |                                              |
| 73   | option finger-server ip-address [, ip-address... ];                     |                                              |
| 74   | option irc-server ip-address [, ip-address... ];                        |                                              |
| 75   | option streettalk-server ip-address [, ip-address... ];                 |                                              |
| 76   | option streettalk-directory-assistance-server ip-address                |                                              |
| 121  |                                                                         | Not implemented.                             |
| 213  | option v4-access-domain domain-name;                                    |                                              |

# Must Implement Options

These are common ones that must be implemented.

* 15 :: domain name
* 213 :: LIS domain name
* 3 :: router
* 51 :: lease time
* 6 :: DNS
* 66 :: TFTP server name
* 60 :: vendor class identifier
* 67 :: bootfile name
