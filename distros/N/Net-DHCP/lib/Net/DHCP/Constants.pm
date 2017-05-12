#!/bin/false
# Net::DHCP::Constants.pm
# Author: Dean Hamstead, Stephan Hadinger

package Net::DHCP::Constants;

# standard module declaration
use 5.8.0;
use strict;
use warnings;

our ( @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS, $VERSION );
use Exporter;
$VERSION = 0.696;
@ISA     = qw(Exporter);

@EXPORT = qw(MAGIC_COOKIE);

# Constants
our ( %DHO_CODES,        %REV_DHO_CODES );
our ( %DHCP_MESSAGE,     %REV_DHCP_MESSAGE );
our ( %BOOTP_CODES,      %REV_BOOTP_CODES );
our ( %HTYPE_CODES,      %REV_HTYPE_CODES );
our ( %NWIP_CODES,       %REV_NWIP_CODES );
our ( %CCC_CODES,        %REV_CCC_CODES );
our ( %GEOCONF_CODES,    %REV_GEOCONF_CODES );
our ( %RELAYAGENT_CODES, %REV_RELAYAGENT_CODES );
our ( %SUBOPTION_CODES );

%EXPORT_TAGS = (
    dho_codes     => [ keys %DHO_CODES ],
    dhcp_message  => [ keys %DHCP_MESSAGE ],
    bootp_codes   => [ keys %BOOTP_CODES ],
    htype_codes   => [ keys %HTYPE_CODES ],
    nwip_codes    => [ keys %NWIP_CODES ],
    ccc_codes     => [ keys %CCC_CODES ],
    geoconf_codes => [ keys %GEOCONF_CODES ],
    ra_codes      => [ keys %RELAYAGENT_CODES ],
    dhcp_hashes   => [
        qw(
          %DHO_CODES %REV_DHO_CODES %DHCP_MESSAGE %REV_DHCP_MESSAGE
          %BOOTP_CODES %REV_BOOTP_CODES %NWIP_CODES %CCC_CODES
          %HTYPE_CODES %REV_HTYPE_CODES %GEOCONF_CODES %REV_GEOCONF_CODES
          %RELAYAGENT_CODES %REV_RELAYAGENT_CODES %SUBOPTION_CODES
          )
    ],
    dhcp_other => [
        qw(MAGIC_COOKIE DHCP_UDP_OVERHEAD DHCP_MAX_MTU BOOTP_MIN_LEN BOOTP_ABSOLUTE_MIN_LEN DHCP_MIN_LEN)
    ]
);

@EXPORT_OK = qw(
  %DHO_CODES %REV_DHO_CODES %DHCP_MESSAGE %REV_DHCP_MESSAGE
  %BOOTP_CODES %REV_BOOTP_CODES %NWIP_CODES %REV_NWIP_CODES
  %HTYPE_CODES %REV_HTYPE_CODES %CCC_CODES %REV_CCC_CODES
  %DHO_FORMATS %GEOCONF_CODES %REV_GEOCONF_CODES
  %RELAYAGENT_CODES %REV_RELAYAGENT_CODES
  %SUBOPTION_CODES
);
Exporter::export_tags('dho_codes');
Exporter::export_tags('dhcp_message');
Exporter::export_tags('bootp_codes');
Exporter::export_tags('htype_codes');
Exporter::export_tags('nwip_codes');
Exporter::export_tags('ccc_codes');
Exporter::export_tags('geoconf_codes');
Exporter::export_ok_tags('dhcp_other');

# MAGIC_COOKIE for DHCP (otherwise it is BOOTP)
use constant MAGIC_COOKIE => "\x63\x82\x53\x63";

use constant DHCP_UDP_OVERHEAD      => ( 14 + 20 + 8 );    # Ethernet + IP + UDP
use constant DHCP_MAX_MTU           => 1500;
use constant BOOTP_ABSOLUTE_MIN_LEN => 236;
use constant BOOTP_MIN_LEN          => 300;
use constant DHCP_MIN_LEN           => 548;

BEGIN {
    %BOOTP_CODES = (
        'BOOTREQUEST' => 1,
        'BOOTREPLY'   => 2
    );

    %HTYPE_CODES = (
        'HTYPE_ETHER'   => 1,
        'HTYPE_IEEE802' => 6,
        'HTYPE_FDDI'    => 8
    );

    %DHO_CODES = (    # RFC 2132
        'DHO_PAD'                                  => 0,
        'DHO_SUBNET_MASK'                          => 1,
        'DHO_TIME_OFFSET'                          => 2,
        'DHO_ROUTERS'                              => 3,
        'DHO_TIME_SERVERS'                         => 4,
        'DHO_NAME_SERVERS'                         => 5,
        'DHO_DOMAIN_NAME_SERVERS'                  => 6,
        'DHO_LOG_SERVERS'                          => 7,
        'DHO_COOKIE_SERVERS'                       => 8,
        'DHO_LPR_SERVERS'                          => 9,
        'DHO_IMPRESS_SERVERS'                      => 10,
        'DHO_RESOURCE_LOCATION_SERVERS'            => 11,
        'DHO_HOST_NAME'                            => 12,
        'DHO_BOOT_SIZE'                            => 13,
        'DHO_MERIT_DUMP'                           => 14,
        'DHO_DOMAIN_NAME'                          => 15,
        'DHO_SWAP_SERVER'                          => 16,
        'DHO_ROOT_PATH'                            => 17,
        'DHO_EXTENSIONS_PATH'                      => 18,
        'DHO_IP_FORWARDING'                        => 19,
        'DHO_NON_LOCAL_SOURCE_ROUTING'             => 20,
        'DHO_POLICY_FILTER'                        => 21,
        'DHO_MAX_DGRAM_REASSEMBLY'                 => 22,
        'DHO_DEFAULT_IP_TTL'                       => 23,
        'DHO_PATH_MTU_AGING_TIMEOUT'               => 24,
        'DHO_PATH_MTU_PLATEAU_TABLE'               => 25,
        'DHO_INTERFACE_MTU'                        => 26,
        'DHO_ALL_SUBNETS_LOCAL'                    => 27,
        'DHO_BROADCAST_ADDRESS'                    => 28,
        'DHO_PERFORM_MASK_DISCOVERY'               => 29,
        'DHO_MASK_SUPPLIER'                        => 30,
        'DHO_ROUTER_DISCOVERY'                     => 31,
        'DHO_ROUTER_SOLICITATION_ADDRESS'          => 32,
        'DHO_STATIC_ROUTES'                        => 33,
        'DHO_TRAILER_ENCAPSULATION'                => 34,
        'DHO_ARP_CACHE_TIMEOUT'                    => 35,
        'DHO_IEEE802_3_ENCAPSULATION'              => 36,
        'DHO_DEFAULT_TCP_TTL'                      => 37,
        'DHO_TCP_KEEPALIVE_INTERVAL'               => 38,
        'DHO_TCP_KEEPALIVE_GARBAGE'                => 39,
        'DHO_NIS_DOMAIN'                           => 40,
        'DHO_NIS_SERVERS'                          => 41,
        'DHO_NTP_SERVERS'                          => 42,
        'DHO_VENDOR_ENCAPSULATED_OPTIONS'          => 43,
        'DHO_NETBIOS_NAME_SERVERS'                 => 44,
        'DHO_NETBIOS_DD_SERVER'                    => 45,
        'DHO_NETBIOS_NODE_TYPE'                    => 46,
        'DHO_NETBIOS_SCOPE'                        => 47,
        'DHO_FONT_SERVERS'                         => 48,
        'DHO_X_DISPLAY_MANAGER'                    => 49,
        'DHO_DHCP_REQUESTED_ADDRESS'               => 50,
        'DHO_DHCP_LEASE_TIME'                      => 51,
        'DHO_DHCP_OPTION_OVERLOAD'                 => 52,
        'DHO_DHCP_MESSAGE_TYPE'                    => 53,
        'DHO_DHCP_SERVER_IDENTIFIER'               => 54,
        'DHO_DHCP_PARAMETER_REQUEST_LIST'          => 55,
        'DHO_DHCP_MESSAGE'                         => 56,
        'DHO_DHCP_MAX_MESSAGE_SIZE'                => 57,
        'DHO_DHCP_RENEWAL_TIME'                    => 58,
        'DHO_DHCP_REBINDING_TIME'                  => 59,
        'DHO_VENDOR_CLASS_IDENTIFIER'              => 60,
        'DHO_DHCP_CLIENT_IDENTIFIER'               => 61,
        'DHO_NWIP_DOMAIN_NAME'                     => 62,
        'DHO_NWIP_SUBOPTIONS'                      => 63,
        'DHO_NISV3_DOMAIN'                         => 64,
        'DHO_NISV3_SERVER'                         => 65,
        'DHO_TFTP_SERVER'                          => 66, # actually named 'server name' by IANA
        'DHO_BOOTFILE'                             => 67,
        'DHO_MOBILE_IP_HOME_AGENT'                 => 68,
        'DHO_SMTP_SERVER'                          => 69,
        'DHO_POP3_SERVER'                          => 70,
        'DHO_NNTP_SERVER'                          => 71,
        'DHO_WWW_SERVER'                           => 72,
        'DHO_FINGER_SERVER'                        => 73,
        'DHO_IRC_SERVER'                           => 74,
        'DHO_STREETTALK_SERVER'                    => 75,
        'DHO_STDA_SERVER'                          => 76,
        'DHO_USER_CLASS'                           => 77,
        'DHO_DIRECTORY_AGENT'                      => 78,
        'DHO_SERVICE_SCOPE'                        => 79,
        'DHO_RAPID_COMMIT'                         => 80,
        'DHO_FQDN'                                 => 81,
        'DHO_DHCP_AGENT_OPTIONS'                   => 82,
        'DHO_ISNS'                                 => 83,
        'DHO_NDS_SERVERS'                          => 85,
        'DHO_NDS_TREE_NAME'                        => 86,
        'DHO_NDS_CONTEXT'                          => 87,
        'DHO_BCMCS_CONTROLLER_DOMAIN_NAME_LIST'    => 88,
        'DHO_BCMCS_CONTROLLER_IPV4_ADDRESS'        => 89,
        'DHO_AUTHENTICATION'                       => 90,
        'DHO_CLIENT_LAST_TRANSACTION_TIME'         => 91,
        'DHO_ASSOCIATED_IP'                        => 92,
        'DHO_CLIENT_SYSTEM'                        => 93,
        'DHO_CLIENT_NDI'                           => 94,
        'DHO_LDAP'                                 => 95,
        'DHO_UUID_GUID'                            => 97,
        'DHO_USER_AUTHENTICATION_PROTOCOL'         => 98,
        'DHO_GEOCONF_CIVIC'                        => 99,
        'DHO_PCODE'                                => 100,
        'DHO_TCODE'                                => 101,
        'DHO_NETINFO_ADDRESS'                      => 112,
        'DHO_NETINFO_TAG'                          => 113,
        'DHO_URL'                                  => 114,
        'DHO_AUTO_CONFIGURE'                       => 116,
        'DHO_NAME_SERVICE_SEARCH'                  => 117,
        'DHO_SUBNET_SELECTION'                     => 118,
        'DHO_DOMAIN_SEARCH'                        => 119,
        'DHO_SIP_SERVERS'                          => 120,
        'DHO_CLASSLESS_STATIC_ROUTE'               => 121,
        'DHO_CCC'                                  => 122,
        'DHO_GEOCONF'                              => 123,
        'DHO_VI_VENDOR_CLASS'                      => 124,
        'DHO_VI_VENDOR_SPECIFIC_INFOMATION'        => 125,
        'DHO_DOCSIS_FULL_SECURITY_SERVER_ADDRESS'  => 128,
        'DHO_TFTP_SERVER_IPPHONE'                  => 128,
        'DHO_ETHERBOOT_SIGNATURE'                  => 128,
        'DHO_CALL_SERVER_ADDRESS'                  => 129,
        'DHO_KERNEL_OPTIONS'                       => 129,
        'DHO_DISCRIMINATION_STRING'                => 130,
        'DHO_ETHERNET_INTERFACE'                   => 130,
        'DHO_REMOTE_STATISTICS_SERVER'             => 131,
        'DHO_VLAN_ID'                              => 132,
        'DHO_L2_PRIORITY'                          => 133,
        'DHO_DSCP'                                 => 134,
        'DHO_PXE'                                  => 135,
        'DHO_HTTP_PROXY_FORPHONES'                 => 135,

        'DHO_OPTION_PANA_AGENT'                    => 136,
        'DHO_OPTION_PANA_V4_LOST'                  => 137,
        'DHO_OPTION_CAPWAP_AC_V4'                  => 138,
        'DHO_OPTION_IPV4_ADDRESS_MOS'              => 139,
        'DHO_OPTION_IPV4_FQDN_MOS'                 => 140,
        'DHO_SIP_UA_CONFIGURATION_SERVICE_DOMAINS' => 141,
        'DHO_GRUB_CONF_PATH'                       => 150,
        'DHO_TFTP_SERVER_ADDRESS'                  => 150,    # not to be confused with 66
        'DHO_ETHERBOOT'                            => 150,
        'DHO_IP_TELEPHONE'                         => 176,
        'DHO_PACKETCABLE_DEPRECATED'               => 177,
        'DHO_ETHERBOOT_TENTATIVE'                  => 177,
        'DHO_PXELINUX_MAGIC'                       => 208,
        'DHO_CONFIGURATION_FILE'                   => 209,
        'DHO_PATH_PREFIX'                          => 210,
        'DHO_REBOOT_TIME'                          => 211,
        'DHO_OPTION_6RD'                           => 212,
        'DHO_OPTION_V4_ACCESS_DOMAIN'              => 213,
        'DHO_SUBNET_ALLOCATION'                    => 220,
        'DHO_VIRTUAL_SUBNET'                       => 221,

        'DHO_CLASSLESS_STATIC_ROUTE_MS'            => 249,

        'DHO_END' => 255
    );

    # Type 53 codes...
    %DHCP_MESSAGE = (

        #RFC2132
        'DHCPDISCOVER'   => 1,
        'DHCPOFFER'      => 2,
        'DHCPREQUEST'    => 3,
        'DHCPDECLINE'    => 4,
        'DHCPACK'        => 5,
        'DHCPNAK'        => 6,
        'DHCPRELEASE'    => 7,
        'DHCPINFORM'     => 8,
        'DHCPFORCERENEW' => 9,

        # RFC4388
        'DHCPLEASEQUERY'      => 10
        , # This is now ratified in RFC4388. If you have an old crappy CMTS you might need to change it with 13
        'DHCPLEASEUNASSIGNED' => 11,
        'DHCPLEASEUNKNOWN'    => 12,
        'DHCPLEASEACTIVE'     => 13,

    );

    # Type 63 sub-option codes...
    %NWIP_CODES = (
        'NWIP_DOES_NOT_EXIST'        => 1,
        'NWIP_EXIST_IN_OPTIONS_AREA' => 2,
        'NWIP_EXIST_IN_SNAME_FILE'   => 3,
        'NWIP_EXIST_BUT_TOO_BIG'     => 4,
        'NWIP_NSQ_BROADCAST'         => 5,
        'NWIP_PREFERRED_DSS'         => 6,
        'NWIP_NEAREST_NWIP_SERVER'   => 7,
        'NWIP_AUTORETRIES'           => 8,
        'NWIP_AUTORETRY_SECS'        => 9,
        'NWIP_1_1'                   => 10,
        'NWIP_PRIMARY_DSS'           => 11,

        #'Unassigned' => '12-255'
    );

    # Type 122 sub option codes
    %CCC_CODES = (
        'CCC_PRIMARY_DHCP_SERVER'        => 1,
        'CCC_SECONDARY_DHCP_SERVER'      => 2,
        'CCC_PROVISIONING_SERVER'        => 3,
        'CCC_AS_REQ_AS_REP_BACKOFFRETRY' => 4,
        'CCC_AP_REQ_AS_REP_BACKOFFRETRY' => 5,
        'CCC_KERBEROS_REALM'             => 6,
        'CCC_TICKET_SERVER_UTILIZATION'  => 7,
        'CCC_PROVISIONING_TIMER'         => 8,
        'CCC_SECURITY_TICKET_CONTROL'    => 9,
        'CCC_KDC_SERVER'                 => 10,
    );

    # Type 123 sub option codes (there are more, but im not sure how to deal with them)
    %GEOCONF_CODES = (
        'GEO_METERS' => 1,
        'GEO_FLOORS' => 2,
    );

    # Type 82 sub option codes
    %RELAYAGENT_CODES = (
        'RA_CIRCUIT_ID'         => 1,
        'RA_REMOTE_ID'          => 2,
        'RA_DOCSIS_CLASS'       => 4,
        'RA_LINK_SELECTION'     => 5,
        'RA_SUBSCRIBER_ID'      => 6,
        'RA_RADIUS_ATTRIBUTES'  => 7,
        'RA_AUTHENTICATION'     => 8,
        'RA_VENDOR_INFO'        => 9,
        'RA_FLAGS'              => 10,
        'RA_SERVER_ID_OVERRIDE' => 11,
    );
}

use constant \%DHO_CODES;
%REV_DHO_CODES = reverse %DHO_CODES;

use constant \%DHCP_MESSAGE;
%REV_DHCP_MESSAGE = reverse %DHCP_MESSAGE;

use constant \%BOOTP_CODES;
%REV_BOOTP_CODES = reverse %BOOTP_CODES;    # for reverse lookup

use constant \%HTYPE_CODES;
%REV_HTYPE_CODES = reverse %HTYPE_CODES;    # for reverse lookup

use constant \%NWIP_CODES;
%REV_NWIP_CODES = reverse %NWIP_CODES;

use constant \%CCC_CODES;
%REV_CCC_CODES = reverse %CCC_CODES;

use constant \%GEOCONF_CODES;
%REV_GEOCONF_CODES = reverse %GEOCONF_CODES;

use constant \%RELAYAGENT_CODES;
%REV_RELAYAGENT_CODES = reverse %RELAYAGENT_CODES;

#
# Format of DHCP options : for pretty-printing
#   void : no parameter
#   inet : 4 bytes IP address
#   inets : list of 4 bytes IP addresses
#   inets2 : list of 4 bytes IP addresses pairs (multiple of 8 bytes)
#   int : 4 bytes integer
#   short : 2 bytes integer
#   shorts : list of 2 bytes integers
#   byte : 1 byte int
#   bytes : list of 1 byte code
#   string : char* (just kidding)
#   relays : DHCP sub-options (rfc 3046)
#   ids : client identifier : byte (htype) + string (chaddr)
#   csr : classless static routes (rfc 3442)
#   suboptions : hex encoded sub options
#
our %DHO_FORMATS = (
    DHO_PAD()                         => 'void',
    DHO_SUBNET_MASK()                 => 'inet',
    DHO_TIME_OFFSET()                 => 'int',
    DHO_ROUTERS()                     => 'inets',
    DHO_TIME_SERVERS()                => 'inets',
    DHO_NAME_SERVERS()                => 'inets',
    DHO_DOMAIN_NAME_SERVERS()         => 'inets',
    DHO_LOG_SERVERS()                 => 'inets',
    DHO_COOKIE_SERVERS()              => 'inets',
    DHO_LPR_SERVERS()                 => 'inets',
    DHO_IMPRESS_SERVERS()             => 'inets',
    DHO_RESOURCE_LOCATION_SERVERS()   => 'inets',
    DHO_HOST_NAME()                   => 'string',
    DHO_BOOT_SIZE()                   => 'short',
    DHO_MERIT_DUMP()                  => 'string',
    DHO_DOMAIN_NAME()                 => 'string',
    DHO_SWAP_SERVER()                 => 'inet',
    DHO_ROOT_PATH()                   => 'string',
    DHO_EXTENSIONS_PATH()             => 'string',
    DHO_IP_FORWARDING()               => 'byte',
    DHO_NON_LOCAL_SOURCE_ROUTING()    => 'byte',
    DHO_POLICY_FILTER()               => 'inets2',
    DHO_MAX_DGRAM_REASSEMBLY()        => 'short',
    DHO_DEFAULT_IP_TTL()              => 'byte',
    DHO_PATH_MTU_AGING_TIMEOUT()      => 'int',
    DHO_PATH_MTU_PLATEAU_TABLE()      => 'shorts',
    DHO_INTERFACE_MTU()               => 'short',
    DHO_ALL_SUBNETS_LOCAL()           => 'byte',
    DHO_BROADCAST_ADDRESS()           => 'inet',
    DHO_PERFORM_MASK_DISCOVERY()      => 'byte',
    DHO_MASK_SUPPLIER()               => 'byte',
    DHO_ROUTER_DISCOVERY()            => 'byte',
    DHO_ROUTER_SOLICITATION_ADDRESS() => 'inet',
    DHO_STATIC_ROUTES()               => 'inets2',
    DHO_TRAILER_ENCAPSULATION()       => 'byte',
    DHO_ARP_CACHE_TIMEOUT()           => 'int',
    DHO_IEEE802_3_ENCAPSULATION()     => 'byte',
    DHO_DEFAULT_TCP_TTL()             => 'byte',
    DHO_TCP_KEEPALIVE_INTERVAL()      => 'int',
    DHO_TCP_KEEPALIVE_GARBAGE()       => 'byte',
    DHO_NIS_DOMAIN()                  => 'string',
    DHO_NIS_SERVERS()                 => 'inets',
    DHO_NTP_SERVERS()                 => 'inets',

    DHO_VENDOR_ENCAPSULATED_OPTIONS() => 'suboptions',
    DHO_NETBIOS_NAME_SERVERS()        => 'inets',
    DHO_NETBIOS_DD_SERVER()           => 'inets',
    DHO_NETBIOS_NODE_TYPE()           => 'byte',
    DHO_NETBIOS_SCOPE()               => 'string',
    DHO_FONT_SERVERS()                => 'inets',
    DHO_X_DISPLAY_MANAGER()           => 'inets',
    DHO_DHCP_REQUESTED_ADDRESS()      => 'inet',
    DHO_DHCP_LEASE_TIME()             => 'int',
    DHO_DHCP_OPTION_OVERLOAD()        => 'byte',
    DHO_DHCP_MESSAGE_TYPE()           => 'byte',
    DHO_DHCP_SERVER_IDENTIFIER()      => 'inet',
    DHO_DHCP_PARAMETER_REQUEST_LIST() => 'bytes',
    DHO_DHCP_MESSAGE()                => 'string',
    DHO_DHCP_MAX_MESSAGE_SIZE()       => 'short',
    DHO_DHCP_RENEWAL_TIME()           => 'int',
    DHO_DHCP_REBINDING_TIME()         => 'int',
    DHO_VENDOR_CLASS_IDENTIFIER()     => 'string',

    #    DHO_DHCP_CLIENT_IDENTIFIER()  => 'ids',
    DHO_NWIP_DOMAIN_NAME()            => 'string',    # rfc 2242

    DHO_NWIP_SUBOPTIONS()             => 'suboptions',                    # rfc 2242
    DHO_NISV3_DOMAIN()                => 'string',
    DHO_NISV3_SERVER()                => 'string',
    DHO_TFTP_SERVER()                 => 'string',
    DHO_BOOTFILE()                    => 'string',
    DHO_MOBILE_IP_HOME_AGENT()        => 'inets',
    DHO_SMTP_SERVER()                 => 'inets',
    DHO_POP3_SERVER()                 => 'inets',
    DHO_NNTP_SERVER()                 => 'inets',
    DHO_WWW_SERVER()                  => 'inets',
    DHO_FINGER_SERVER()               => 'inets',
    DHO_IRC_SERVER()                  => 'inets',
    DHO_STREETTALK_SERVER()           => 'inets',
    DHO_STDA_SERVER()                 => 'inets',

    DHO_CCC                           => 'suboptions',

#    DHO_USER_CLASS()  => '',                        # rfc 3004
#    DHO_FQDN()  => '',                              # draft-ietf-dhc-fqdn-option-10.txt
#    DHO_DHCP_AGENT_OPTIONS()  => 'relays',             # rfc 3046
    DHO_DHCP_AGENT_OPTIONS()           => 'string',    # rfc 3046
    DHO_NDS_SERVERS()                  => 'inets',     # rfc 2241
    DHO_NDS_TREE_NAME()                => 'string',    # rfc 2241
    DHO_USER_AUTHENTICATION_PROTOCOL() => 'string',    # rfc 2485
    DHO_AUTO_CONFIGURE()               => 'byte',      # rfc 2563
    DHO_NAME_SERVICE_SEARCH()          => 'shorts',    # rfc 2937
    DHO_SUBNET_SELECTION()             => 'inet',      # rfc 3011

    DHO_CLASSLESS_STATIC_ROUTE()      => 'csr',        # rfc 3442
    DHO_CLASSLESS_STATIC_ROUTE_MS()   => 'csr',
);

# Links option codes with their suboption values
%SUBOPTION_CODES = (
    $DHO_CODES{'DHO_NWIP_SUBOPTIONS'}    => \%NWIP_CODES, # option 63
    $DHO_CODES{'DHO_DHCP_AGENT_OPTIONS'} => \%RELAYAGENT_CODES, # option 82
    $DHO_CODES{'DHO_CCC'}                => \%CCC_CODES,  # option 122
    $DHO_CODES{'DHO_GEOCONF'}            => \%GEOCONF_CODES, # option 123
);

1;

=pod

=head1 NAME

Net::DHCP::Constants - Constants for DHCP codes and options

=head1 VERSION

version 0.696

=head1 SYNOPSIS

  use Net::DHCP::Constants;
  print "DHCP option SUBNET_MASK is ", DHO_SUBNET_MASK();

=head1 DESCRIPTION

Represents constants used in DHCP protocol, defined in RFC 1533, RFC 2132,
RFC 2241, RFC 2485, RFC 2563, RFC 2937, RFC 3004, RFC 3011, RFC 3046.

=head1 TAGS

As mentioned above, constants can either be imported individually
or in sets grouped by tag names. The tag names are:

=over 4

=item * bootp_codes

Imports all of the basic I<BOOTP> constants.

  (01) BOOTREQUEST
  (02) BOOTREPLY

=item * htype_codes

Imports all I<HTYPE> (hardware address type) codes.

  (01) HTYPE_ETHER
  (06) HTYPE_IEEE802
  (08) HTYPE_FDDI

Most common value is HTYPE_ETHER for C<Ethernet>.

=item * dhcp_message

Import all DHCP Message codes.

(rfc2132)

  (01) DHCPDISCOVER
  (02) DHCPOFFER
  (03) DHCPREQUEST
  (04) DHCPDECLINE
  (05) DHCPACK
  (06) DHCPNAK
  (07) DHCPRELEASE
  (08) DHCPINFORM
  (09) DHCPFORCERENEW

(rfc4388)

  (10) DHCPLEASEQUERY
  (11) DHCPLEASEUNASSIGNED
  (12) DHCPLEASEUNKNOWN
  (13) DHCPLEASEACTIVE

Nb. Previously Cisco used 13 for DHCPLEASEQUERY. If you need to decode
or encode packets to communicate with such a system, you might simply
use the integer rather than the constant - or use the updated constant
and comment in your code appropriately.

=item * dho_codes

Import all DHCP option codes.

  (000) DHO_PAD
  (001) DHO_SUBNET_MASK
  (002) DHO_TIME_OFFSET
  (003) DHO_ROUTERS
  (004) DHO_TIME_SERVERS
  (005) DHO_NAME_SERVERS
  (006) DHO_DOMAIN_NAME_SERVERS
  (007) DHO_LOG_SERVERS
  (008) DHO_COOKIE_SERVERS
  (009) DHO_LPR_SERVERS
  (010) DHO_IMPRESS_SERVERS
  (011) DHO_RESOURCE_LOCATION_SERVERS
  (012) DHO_HOST_NAME
  (013) DHO_BOOT_SIZE
  (014) DHO_MERIT_DUMP
  (015) DHO_DOMAIN_NAME
  (016) DHO_SWAP_SERVER
  (017) DHO_ROOT_PATH
  (018) DHO_EXTENSIONS_PATH
  (019) DHO_IP_FORWARDING
  (020) DHO_NON_LOCAL_SOURCE_ROUTING
  (021) DHO_POLICY_FILTER
  (022) DHO_MAX_DGRAM_REASSEMBLY
  (023) DHO_DEFAULT_IP_TTL
  (024) DHO_PATH_MTU_AGING_TIMEOUT
  (025) DHO_PATH_MTU_PLATEAU_TABLE
  (026) DHO_INTERFACE_MTU
  (027) DHO_ALL_SUBNETS_LOCAL
  (028) DHO_BROADCAST_ADDRESS
  (029) DHO_PERFORM_MASK_DISCOVERY
  (030) DHO_MASK_SUPPLIER
  (031) DHO_ROUTER_DISCOVERY
  (032) DHO_ROUTER_SOLICITATION_ADDRESS
  (033) DHO_STATIC_ROUTES
  (034) DHO_TRAILER_ENCAPSULATION
  (035) DHO_ARP_CACHE_TIMEOUT
  (036) DHO_IEEE802_3_ENCAPSULATION
  (037) DHO_DEFAULT_TCP_TTL
  (038) DHO_TCP_KEEPALIVE_INTERVAL
  (039) DHO_TCP_KEEPALIVE_GARBAGE
  (040) DHO_NIS_DOMAIN
  (041) DHO_NIS_SERVERS
  (042) DHO_NTP_SERVERS
  (043) DHO_VENDOR_ENCAPSULATED_OPTIONS
  (044) DHO_NETBIOS_NAME_SERVERS
  (045) DHO_NETBIOS_DD_SERVER
  (046) DHO_NETBIOS_NODE_TYPE
  (047) DHO_NETBIOS_SCOPE
  (048) DHO_FONT_SERVERS
  (049) DHO_X_DISPLAY_MANAGER
  (050) DHO_DHCP_REQUESTED_ADDRESS
  (051) DHO_DHCP_LEASE_TIME
  (052) DHO_DHCP_OPTION_OVERLOAD
  (053) DHO_DHCP_MESSAGE_TYPE
  (054) DHO_DHCP_SERVER_IDENTIFIER
  (055) DHO_DHCP_PARAMETER_REQUEST_LIST
  (056) DHO_DHCP_MESSAGE
  (057) DHO_DHCP_MAX_MESSAGE_SIZE
  (058) DHO_DHCP_RENEWAL_TIME
  (059) DHO_DHCP_REBINDING_TIME
  (060) DHO_VENDOR_CLASS_IDENTIFIER
  (061) DHO_DHCP_CLIENT_IDENTIFIER
  (062) DHO_NWIP_DOMAIN_NAME
  (063) DHO_NWIP_SUBOPTIONS
  (064) DHO_NISV3_DOMAIN
  (065) DHO_NISV3_SERVER
  (066) DHO_TFTP_SERVER
  (067) DHO_BOOTFILE
  (068) DHO_MOBILE_IP_HOME_AGENT
  (069) DHO_SMTP_SERVER
  (070) DHO_POP3_SERVER
  (071) DHO_NNTP_SERVER
  (072) DHO_WWW_SERVER
  (073) DHO_FINGER_SERVER
  (074) DHO_IRC_SERVER
  (075) DHO_STREETTALK_SERVER
  (076) DHO_STDA_SERVER
  (077) DHO_USER_CLASS
  (078) DHO_DIRECTORY_AGENT
  (079) DHO_SERVICE_SCOPE
  (080) DHO_RAPID_COMMIT
  (081) DHO_FQDN
  (082) DHO_DHCP_AGENT_OPTIONS
  (083) DHO_ISNS
  (085) DHO_NDS_SERVERS
  (086) DHO_NDS_TREE_NAME
  (087) DHO_NDS_CONTEXT
  (088) DHO_BCMCS_CONTROLLER_DOMAIN_NAME_LIST
  (089) DHO_BCMCS_CONTROLLER_IPV4_ADDRESS
  (090) DHO_AUTHENTICATION
  (091) DHO_CLIENT_LAST_TRANSACTION_TIME
  (092) DHO_ASSOCIATED_IP
  (093) DHO_CLIENT_SYSTEM
  (094) DHO_CLIENT_NDI
  (095) DHO_LDAP
  (097) DHO_UUID_GUID
  (098) DHO_USER_AUTHENTICATION_PROTOCOL
  (099) DHO_GEOCONF_CIVIC
  (100) DHO_PCODE
  (101) DHO_TCODE
  (112) DHO_NETINFO_ADDRESS
  (113) DHO_NETINFO_TAG
  (114) DHO_URL
  (116) DHO_AUTO_CONFIGURE
  (117) DHO_NAME_SERVICE_SEARCH
  (118) DHO_SUBNET_SELECTION
  (119) DHO_DOMAIN_SEARCH
  (120) DHO_SIP_SERVERS
  (121) DHO_CLASSLESS_STATIC_ROUTE
  (122) DHO_CCC
  (123) DHO_GEOCONF
  (124) DHO_VI_VENDOR_CLASS
  (125) DHO_VI_VENDOR_SPECIFIC_INFOMATION
  (128) DHO_ETHERBOOT_SIGNATURE
  (129) DHO_CALL_SERVER_ADDRESS
  (130) DHO_DISCRIMINATION_STRING
  (131) DHO_REMOTE_STATISTICS_SERVER
  (132) DHO_VLAN_ID
  (133) DHO_L2_PRIORITY
  (134) DHO_DSCP
  (135) DHO_HTTP_PROXY_FORPHONES
  (136) DHO_OPTION_PANA_AGENT
  (137) DHO_OPTION_PANA_V4_LOST
  (138) DHO_OPTION_CAPWAP_AC_V4
  (139) DHO_OPTION_IPV4_ADDRESS_MOS
  (140) DHO_OPTION_IPV4_FQDN_MOS
  (141) DHO_SIP_UA_CONFIGURATION_SERVICE_DOMAINS
  (150) DHO_ETHERBOOT
  (176) DHO_IP_TELEPHONE
  (177) DHO_PACKETCABLE_DEPRECATED
  (208) DHO_PXELINUX_MAGIC
  (209) DHO_CONFIGURATION_FILE
  (210) DHO_PATH_PREFIX
  (211) DHO_REBOOT_TIME
  (212) DHO_OPTION_6RD
  (213) DHO_OPTION_V4_ACCESS_DOMAIN
  (220) DHO_SUBNET_ALLOCATION
  (221) DHO_VIRTUAL_SUBNET
  (249) DHO_CLASSLESS_STATIC_ROUTE_MS
  (255) DHO_END

=item * ccc_codes

Import all CableLabs Client Configuration

  (001) CCC_PRIMARY_DHCP_SERVER
  (002) CCC_SECONDARY_DHCP_SERVER
  (003) CCC_PROVISIONING_SERVER
  (004) CCC_AS_REQ_AS_REP_BACKOFFRETRY
  (005) CCC_AP_REQ_AS_REP_BACKOFFRETRY
  (006) CCC_KERBEROS_REALM
  (007) CCC_TICKET_SERVER_UTILIZATION
  (008) CCC_PROVISIONING_TIMER
  (009) CCC_SECURITY_TICKET_CONTROL
  (010) CCC_KDC_SERVER

=back

=head1 TO DO, LIMITATIONS

Automatic parsing of DHO_VENDOR_ENCAPSULATED_OPTIONS (code 43) is unsupported.

Automatic parsing of DHO_NWIP_SUBOPTIONS (code 63 - rfc 2242) is unsupported.

Automatic parsing of DHO_USER_CLASS (code 77 - rfc 3004) is unsupported.

Automatic parsing of DHO_CCC (code 122 - rfc 3495) is unsupported.

Automatic parsing of DHO_PACKETCABLE_DEPRECATED (code 177 - rfc 3495) is unsupported.

=head1 SEE ALSO

L<Net::DHCP::Packet>, L<Net::DHCP::Options>

=head1 AUTHOR

Dean Hamstead E<lt>djzort@cpan.orgE<gt> and past Authors (see README)

=head1 GOT PATCHES?

Many young people like to use Github, so by all means send me pull requests at

https://github.com/djzort/Net-DHCP

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
