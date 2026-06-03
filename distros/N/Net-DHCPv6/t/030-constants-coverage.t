#!/usr/bin/env perl
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
# ABSTRACT: Validate every constant against IANA/RFC values and verify option class coverage
use strictures 2;
use Test2::V1 -ipP, qw(is ok subtest pass note done_testing);    ## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)

use lib 't/lib';
use lib 'lib';

use Net::DHCPv6            ();
use Net::DHCPv6::Constants qw(
    $ADVERTISE
    $CLIENT_ARCH_ARC_X86 $CLIENT_ARCH_ARM_32_UBOOT $CLIENT_ARCH_ARM_32_UEFI
    $CLIENT_ARCH_ARM_32_UEFI_HTTP $CLIENT_ARCH_ARM_64_UBOOT
    $CLIENT_ARCH_ARM_64_UEFI $CLIENT_ARCH_ARM_64_UEFI_HTTP
    $CLIENT_ARCH_ARM_RPIBOOT $CLIENT_ARCH_ARM_UBOOT_32_HTTP
    $CLIENT_ARCH_ARM_UBOOT_64_HTTP $CLIENT_ARCH_DEC_ALPHA $CLIENT_ARCH_EBC
    $CLIENT_ARCH_EBC_HTTP $CLIENT_ARCH_EFI_XSCALE
    $CLIENT_ARCH_INTEL_LEAN_CLIENT $CLIENT_ARCH_ITANIUM
    $CLIENT_ARCH_LOONGARCH_32_UEFI $CLIENT_ARCH_LOONGARCH_32_UEFI_HTTP
    $CLIENT_ARCH_LOONGARCH_64_UEFI $CLIENT_ARCH_LOONGARCH_64_UEFI_HTTP
    $CLIENT_ARCH_MIPS_32_UEFI $CLIENT_ARCH_MIPS_64_UEFI
    $CLIENT_ARCH_NEC_PC98 $CLIENT_ARCH_PC_AT_BIOS_HTTP
    $CLIENT_ARCH_POWER_OPAL_V3 $CLIENT_ARCH_PPC_EPAPR
    $CLIENT_ARCH_PPC_OPEN_FIRMWARE $CLIENT_ARCH_RISCV_128_UEFI
    $CLIENT_ARCH_RISCV_128_UEFI_HTTP $CLIENT_ARCH_RISCV_32_UEFI
    $CLIENT_ARCH_RISCV_32_UEFI_HTTP $CLIENT_ARCH_RISCV_64_UEFI
    $CLIENT_ARCH_RISCV_64_UEFI_HTTP $CLIENT_ARCH_S390_BASIC
    $CLIENT_ARCH_S390_EXTENDED $CLIENT_ARCH_SUNWAY_32_UEFI
    $CLIENT_ARCH_SUNWAY_64_UEFI $CLIENT_ARCH_X64_UEFI
    $CLIENT_ARCH_X64_UEFI_HTTP $CLIENT_ARCH_X86_BIOS $CLIENT_ARCH_X86_UEFI
    $CLIENT_ARCH_X86_UEFI_HTTP $CLIENT_FQDN_N $CLIENT_FQDN_O $CLIENT_FQDN_S
    $CONFIRM
    $DECLINE $DUID_EN $DUID_LL $DUID_LLT $DUID_UUID
    $INFORMATION_REQUEST
    $LINK_TYPE_AETHERNET $LINK_TYPE_ARCNET $LINK_TYPE_ARP_SEC
    $LINK_TYPE_ATM $LINK_TYPE_ATM_ALT $LINK_TYPE_ATM_RFC2225
    $LINK_TYPE_AUTONET $LINK_TYPE_AX25 $LINK_TYPE_CHAOS
    $LINK_TYPE_ETHERNET $LINK_TYPE_EUI64 $LINK_TYPE_EXP_ETHERNET
    $LINK_TYPE_FIBRE_CHANNEL $LINK_TYPE_FRAME_RELAY $LINK_TYPE_HDLC
    $LINK_TYPE_HFI $LINK_TYPE_HIPARP $LINK_TYPE_HW_EXP1 $LINK_TYPE_HW_EXP2
    $LINK_TYPE_HYPERCHANNEL $LINK_TYPE_IEEE1394 $LINK_TYPE_IEEE802
    $LINK_TYPE_INFINIBAND $LINK_TYPE_IPSEC_TUNNEL $LINK_TYPE_ISO7816
    $LINK_TYPE_LANSTAR $LINK_TYPE_LOCALNET $LINK_TYPE_LOCALTALK
    $LINK_TYPE_MAPOS $LINK_TYPE_METRICOM $LINK_TYPE_MIL_STD_188_220
    $LINK_TYPE_PRONET $LINK_TYPE_PURE_IP $LINK_TYPE_RESERVED
    $LINK_TYPE_RESERVED_HIGH $LINK_TYPE_SERIAL $LINK_TYPE_SMDS
    $LINK_TYPE_TIA_102 $LINK_TYPE_TWINAXIAL $LINK_TYPE_ULTRA
    $LINK_TYPE_UNIFIED_BUS $LINK_TYPE_WIEGAND
    $OPTION_AFTR_NAME $OPTION_AUTH $OPTION_BOOTFILE_PARAM
    $OPTION_BOOTFILE_URL $OPTION_CAPTIVE_PORTAL $OPTION_CLIENT_ARCH_TYPE
    $OPTION_CLIENT_FQDN $OPTION_CLIENTID $OPTION_CLIENT_LINKLAYER_ADDR
    $OPTION_DNS_SERVERS $OPTION_DOMAIN_LIST $OPTION_ELAPSED_TIME
    $OPTION_IAADDR $OPTION_IA_NA $OPTION_IA_PD $OPTION_IAPREFIX
    $OPTION_IA_TA $OPTION_INF_MAX_RT $OPTION_INFORMATION_REFRESH_TIME
    $OPTION_INTERFACE_ID $OPTION_MUD_URL $OPTION_NEW_POSIX_TIMEZONE
    $OPTION_NEW_TZDB_TIMEZONE $OPTION_NIS_DOMAIN_NAME
    $OPTION_NISP_DOMAIN_NAME $OPTION_NISP_SERVERS $OPTION_NIS_SERVERS
    $OPTION_NTP_SERVER $OPTION_ORO $OPTION_PD_EXCLUDE $OPTION_PREFERENCE
    $OPTION_RAPID_COMMIT $OPTION_RECONF_ACCEPT $OPTION_RECONF_MSG
    $OPTION_RELAY_MSG $OPTION_REMOTE_ID $OPTION_RSOO $OPTION_SERVERID
    $OPTION_SIP_SERVER_A $OPTION_SIP_SERVER_D $OPTION_SNTP_SERVERS
    $OPTION_SOL_MAX_RT $OPTION_STATUS_CODE $OPTION_SUBSCRIBER_ID
    $OPTION_UNICAST $OPTION_USER_CLASS $OPTION_VENDOR_CLASS
    $OPTION_VENDOR_OPTS
    $REBIND $RECONFIGURE $RELAY_FORW $RELAY_REPLY $RELEASE $RENEW $REPLY
    $REQUEST
    $SOLICIT
    $STATUS_NO_ADDRS_AVAIL $STATUS_NO_BINDING $STATUS_NO_PREFIX_AVAIL
    $STATUS_NOT_ON_LINK $STATUS_SUCCESS $STATUS_UNSPEC_FAIL
    $STATUS_USE_MULTICAST
);
use Net::DHCPv6::OptionList ();

# -------------------------------------------------------------------
# Helper: check that $OPTION_XXX constant exists, matches expected
# value, is registered in REV_OPTION_CODE, and has an option class.
# -------------------------------------------------------------------
my %OPTION_CLASS_CODES = %Net::DHCPv6::OptionList::OPTION_CLASS;

sub check_option_constant {
    my ( $name, $expected, $desc ) = @_;
    ( my $short = $name ) =~ s/^OPTION_//;
    is( Net::DHCPv6::Constants::option_name( $expected ), $short, "$desc: REV_OPTION_CODE{$expected} eq $short" );
    exists $OPTION_CLASS_CODES{$expected}
        ? pass( "$desc: option class registered for code $expected" )
        : note( "$desc: no dedicated option class for code $expected (Generic OK)" );
    return;
}

# -------------------------------------------------------------------
# Message types (RFC 8415 Section 14)
# -------------------------------------------------------------------
subtest 'Message types' => sub {
    is( $SOLICIT,             1,  'SOLICIT' );
    is( $ADVERTISE,           2,  'ADVERTISE' );
    is( $REQUEST,             3,  'REQUEST' );
    is( $CONFIRM,             4,  'CONFIRM' );
    is( $RENEW,               5,  'RENEW' );
    is( $REBIND,              6,  'REBIND' );
    is( $REPLY,               7,  'REPLY' );
    is( $RELEASE,             8,  'RELEASE' );
    is( $DECLINE,             9,  'DECLINE' );
    is( $RECONFIGURE,         10, 'RECONFIGURE' );
    is( $INFORMATION_REQUEST, 11, 'INFORMATION_REQUEST' );
    is( $RELAY_FORW,          12, 'RELAY_FORW' );
    is( $RELAY_REPLY,         13, 'RELAY_REPLY' );

    is( Net::DHCPv6::Constants::message_type_name( 1 ),  'SOLICIT',     'REV_MESSAGE_TYPE 1' );
    is( Net::DHCPv6::Constants::message_type_name( 13 ), 'RELAY_REPLY', 'REV_MESSAGE_TYPE 13' );
    ok( !defined Net::DHCPv6::Constants::message_type_name( 99 ), 'REV_MESSAGE_TYPE 99 is undef' );
    ok( Net::DHCPv6::Constants::is_valid_message_type( 1 ),       'is_valid 1' );
    ok( Net::DHCPv6::Constants::is_valid_message_type( 13 ),      'is_valid 13' );
    ok( !Net::DHCPv6::Constants::is_valid_message_type( 0 ),      'is_valid 0 false' );
    ok( !Net::DHCPv6::Constants::is_valid_message_type( 99 ),     'is_valid 99 false' );
};

# -------------------------------------------------------------------
# Option codes (RFC 8415 Section 21)
# -------------------------------------------------------------------
subtest 'Option codes' => sub {
    is( $OPTION_CLIENTID,                 1,   'OPTION_CLIENTID' );
    is( $OPTION_SERVERID,                 2,   'OPTION_SERVERID' );
    is( $OPTION_IA_NA,                    3,   'OPTION_IA_NA' );
    is( $OPTION_IA_TA,                    4,   'OPTION_IA_TA' );
    is( $OPTION_IAADDR,                   5,   'OPTION_IAADDR' );
    is( $OPTION_ORO,                      6,   'OPTION_ORO' );
    is( $OPTION_PREFERENCE,               7,   'OPTION_PREFERENCE' );
    is( $OPTION_ELAPSED_TIME,             8,   'OPTION_ELAPSED_TIME' );
    is( $OPTION_RELAY_MSG,                9,   'OPTION_RELAY_MSG' );
    is( $OPTION_AUTH,                     11,  'OPTION_AUTH' );
    is( $OPTION_UNICAST,                  12,  'OPTION_UNICAST' );
    is( $OPTION_STATUS_CODE,              13,  'OPTION_STATUS_CODE' );
    is( $OPTION_RAPID_COMMIT,             14,  'OPTION_RAPID_COMMIT' );
    is( $OPTION_USER_CLASS,               15,  'OPTION_USER_CLASS' );
    is( $OPTION_VENDOR_CLASS,             16,  'OPTION_VENDOR_CLASS' );
    is( $OPTION_VENDOR_OPTS,              17,  'OPTION_VENDOR_OPTS' );
    is( $OPTION_INTERFACE_ID,             18,  'OPTION_INTERFACE_ID' );
    is( $OPTION_RECONF_MSG,               19,  'OPTION_RECONF_MSG' );
    is( $OPTION_RECONF_ACCEPT,            20,  'OPTION_RECONF_ACCEPT' );
    is( $OPTION_SIP_SERVER_D,             21,  'OPTION_SIP_SERVER_D' );
    is( $OPTION_SIP_SERVER_A,             22,  'OPTION_SIP_SERVER_A' );
    is( $OPTION_DNS_SERVERS,              23,  'OPTION_DNS_SERVERS' );
    is( $OPTION_DOMAIN_LIST,              24,  'OPTION_DOMAIN_LIST' );
    is( $OPTION_IA_PD,                    25,  'OPTION_IA_PD' );
    is( $OPTION_IAPREFIX,                 26,  'OPTION_IAPREFIX' );
    is( $OPTION_NIS_SERVERS,              27,  'OPTION_NIS_SERVERS' );
    is( $OPTION_NISP_SERVERS,             28,  'OPTION_NISP_SERVERS' );
    is( $OPTION_NIS_DOMAIN_NAME,          29,  'OPTION_NIS_DOMAIN_NAME' );
    is( $OPTION_NISP_DOMAIN_NAME,         30,  'OPTION_NISP_DOMAIN_NAME' );
    is( $OPTION_SNTP_SERVERS,             31,  'OPTION_SNTP_SERVERS' );
    is( $OPTION_INFORMATION_REFRESH_TIME, 32,  'OPTION_INFORMATION_REFRESH_TIME' );
    is( $OPTION_REMOTE_ID,                37,  'OPTION_REMOTE_ID' );
    is( $OPTION_SUBSCRIBER_ID,            38,  'OPTION_SUBSCRIBER_ID' );
    is( $OPTION_CLIENT_FQDN,              39,  'OPTION_CLIENT_FQDN' );
    is( $OPTION_NEW_POSIX_TIMEZONE,       41,  'OPTION_NEW_POSIX_TIMEZONE' );
    is( $OPTION_NEW_TZDB_TIMEZONE,        42,  'OPTION_NEW_TZDB_TIMEZONE' );
    is( $OPTION_NTP_SERVER,               56,  'OPTION_NTP_SERVER' );
    is( $OPTION_BOOTFILE_URL,             59,  'OPTION_BOOTFILE_URL' );
    is( $OPTION_BOOTFILE_PARAM,           60,  'OPTION_BOOTFILE_PARAM' );
    is( $OPTION_CLIENT_ARCH_TYPE,         61,  'OPTION_CLIENT_ARCH_TYPE' );
    is( $OPTION_AFTR_NAME,                64,  'OPTION_AFTR_NAME' );
    is( $OPTION_RSOO,                     66,  'OPTION_RSOO' );
    is( $OPTION_PD_EXCLUDE,               67,  'OPTION_PD_EXCLUDE' );
    is( $OPTION_CLIENT_LINKLAYER_ADDR,    79,  'OPTION_CLIENT_LINKLAYER_ADDR' );
    is( $OPTION_SOL_MAX_RT,               82,  'OPTION_SOL_MAX_RT' );
    is( $OPTION_INF_MAX_RT,               83,  'OPTION_INF_MAX_RT' );
    is( $OPTION_CAPTIVE_PORTAL,           103, 'OPTION_CAPTIVE_PORTAL' );
    is( $OPTION_MUD_URL,                  112, 'OPTION_MUD_URL' );

    check_option_constant( 'OPTION_CLIENTID',                 1,   'Client Identifier' );
    check_option_constant( 'OPTION_SERVERID',                 2,   'Server Identifier' );
    check_option_constant( 'OPTION_IA_NA',                    3,   'IA_NA' );
    check_option_constant( 'OPTION_IA_TA',                    4,   'IA_TA' );
    check_option_constant( 'OPTION_IAADDR',                   5,   'IA_ADDR' );
    check_option_constant( 'OPTION_ORO',                      6,   'ORO' );
    check_option_constant( 'OPTION_PREFERENCE',               7,   'Preference' );
    check_option_constant( 'OPTION_ELAPSED_TIME',             8,   'Elapsed Time' );
    check_option_constant( 'OPTION_RELAY_MSG',                9,   'Relay Message' );
    check_option_constant( 'OPTION_AUTH',                     11,  'Authentication' );
    check_option_constant( 'OPTION_UNICAST',                  12,  'Unicast' );
    check_option_constant( 'OPTION_STATUS_CODE',              13,  'Status Code' );
    check_option_constant( 'OPTION_RAPID_COMMIT',             14,  'Rapid Commit' );
    check_option_constant( 'OPTION_USER_CLASS',               15,  'User Class' );
    check_option_constant( 'OPTION_VENDOR_CLASS',             16,  'Vendor Class' );
    check_option_constant( 'OPTION_VENDOR_OPTS',              17,  'Vendor-specific Info' );
    check_option_constant( 'OPTION_INTERFACE_ID',             18,  'Interface ID' );
    check_option_constant( 'OPTION_RECONF_MSG',               19,  'Reconfigure Message' );
    check_option_constant( 'OPTION_RECONF_ACCEPT',            20,  'Reconfigure Accept' );
    check_option_constant( 'OPTION_SIP_SERVER_D',             21,  'SIP Server Domain Name' );
    check_option_constant( 'OPTION_SIP_SERVER_A',             22,  'SIP Server IPv6 Address' );
    check_option_constant( 'OPTION_DNS_SERVERS',              23,  'DNS Recursive Name Servers' );
    check_option_constant( 'OPTION_DOMAIN_LIST',              24,  'Domain Search List' );
    check_option_constant( 'OPTION_IA_PD',                    25,  'IA_PD' );
    check_option_constant( 'OPTION_IAPREFIX',                 26,  'IAPREFIX' );
    check_option_constant( 'OPTION_NIS_SERVERS',              27,  'NIS Servers' );
    check_option_constant( 'OPTION_NISP_SERVERS',             28,  'NIS+ Servers' );
    check_option_constant( 'OPTION_NIS_DOMAIN_NAME',          29,  'NIS Domain Name' );
    check_option_constant( 'OPTION_NISP_DOMAIN_NAME',         30,  'NIS+ Domain Name' );
    check_option_constant( 'OPTION_SNTP_SERVERS',             31,  'SNTP Servers' );
    check_option_constant( 'OPTION_INFORMATION_REFRESH_TIME', 32,  'Information Refresh Time' );
    check_option_constant( 'OPTION_REMOTE_ID',                37,  'Remote ID' );
    check_option_constant( 'OPTION_SUBSCRIBER_ID',            38,  'Subscriber ID' );
    check_option_constant( 'OPTION_CLIENT_FQDN',              39,  'Client FQDN' );
    check_option_constant( 'OPTION_NEW_POSIX_TIMEZONE',       41,  'New POSIX Timezone' );
    check_option_constant( 'OPTION_NEW_TZDB_TIMEZONE',        42,  'New TZDB Timezone' );
    check_option_constant( 'OPTION_NTP_SERVER',               56,  'NTP Server' );
    check_option_constant( 'OPTION_BOOTFILE_URL',             59,  'Boot File URL' );
    check_option_constant( 'OPTION_BOOTFILE_PARAM',           60,  'Boot File Parameters' );
    check_option_constant( 'OPTION_CLIENT_ARCH_TYPE',         61,  'Client Arch Type' );
    check_option_constant( 'OPTION_AFTR_NAME',                64,  'AFTR Name' );
    check_option_constant( 'OPTION_RSOO',                     66,  'Relay-Supplied Options' );
    check_option_constant( 'OPTION_PD_EXCLUDE',               67,  'PD Exclude' );
    check_option_constant( 'OPTION_CLIENT_LINKLAYER_ADDR',    79,  'Client Link-Layer Address' );
    check_option_constant( 'OPTION_SOL_MAX_RT',               82,  'SOL_MAX_RT' );
    check_option_constant( 'OPTION_INF_MAX_RT',               83,  'INF_MAX_RT' );
    check_option_constant( 'OPTION_CAPTIVE_PORTAL',           103, 'Captive Portal' );
    check_option_constant( 'OPTION_MUD_URL',                  112, 'MUD URL' );
};

# -------------------------------------------------------------------
# Status codes (RFC 8415 Section 18.3)
# -------------------------------------------------------------------
subtest 'Status codes' => sub {
    is( $STATUS_SUCCESS,         0, 'STATUS_SUCCESS' );
    is( $STATUS_UNSPEC_FAIL,     1, 'STATUS_UNSPEC_FAIL' );
    is( $STATUS_NO_ADDRS_AVAIL,  2, 'STATUS_NO_ADDRS_AVAIL' );
    is( $STATUS_NO_BINDING,      3, 'STATUS_NO_BINDING' );
    is( $STATUS_NOT_ON_LINK,     4, 'STATUS_NOT_ON_LINK' );
    is( $STATUS_USE_MULTICAST,   5, 'STATUS_USE_MULTICAST' );
    is( $STATUS_NO_PREFIX_AVAIL, 6, 'STATUS_NO_PREFIX_AVAIL' );

    is( Net::DHCPv6::Constants::status_name( 0 ), 'SUCCESS',         'REV_STATUS_CODE 0' );
    is( Net::DHCPv6::Constants::status_name( 6 ), 'NO_PREFIX_AVAIL', 'REV_STATUS_CODE 6' );
    ok( !defined Net::DHCPv6::Constants::status_name( 99 ), 'REV_STATUS_CODE 99 undef' );
};

# -------------------------------------------------------------------
# DUID types (RFC 8415 Section 11)
# -------------------------------------------------------------------
subtest 'DUID types' => sub {
    is( $DUID_LLT,  1, 'DUID_LLT' );
    is( $DUID_EN,   2, 'DUID_EN' );
    is( $DUID_LL,   3, 'DUID_LL' );
    is( $DUID_UUID, 4, 'DUID_UUID' );
};

# -------------------------------------------------------------------
# Client architecture types (IANA Processor Architecture Types, RFC 5970)
# -------------------------------------------------------------------
subtest 'Client architecture types' => sub {
    is( $CLIENT_ARCH_X86_BIOS,               0,  'CLIENT_ARCH_X86_BIOS' );
    is( $CLIENT_ARCH_NEC_PC98,               1,  'CLIENT_ARCH_NEC_PC98' );
    is( $CLIENT_ARCH_ITANIUM,                2,  'CLIENT_ARCH_ITANIUM' );
    is( $CLIENT_ARCH_DEC_ALPHA,              3,  'CLIENT_ARCH_DEC_ALPHA' );
    is( $CLIENT_ARCH_ARC_X86,                4,  'CLIENT_ARCH_ARC_X86' );
    is( $CLIENT_ARCH_INTEL_LEAN_CLIENT,      5,  'CLIENT_ARCH_INTEL_LEAN_CLIENT' );
    is( $CLIENT_ARCH_X86_UEFI,               6,  'CLIENT_ARCH_X86_UEFI' );
    is( $CLIENT_ARCH_X64_UEFI,               7,  'CLIENT_ARCH_X64_UEFI' );
    is( $CLIENT_ARCH_EFI_XSCALE,             8,  'CLIENT_ARCH_EFI_XSCALE' );
    is( $CLIENT_ARCH_EBC,                    9,  'CLIENT_ARCH_EBC' );
    is( $CLIENT_ARCH_ARM_32_UEFI,            10, 'CLIENT_ARCH_ARM_32_UEFI' );
    is( $CLIENT_ARCH_ARM_64_UEFI,            11, 'CLIENT_ARCH_ARM_64_UEFI' );
    is( $CLIENT_ARCH_PPC_OPEN_FIRMWARE,      12, 'CLIENT_ARCH_PPC_OPEN_FIRMWARE' );
    is( $CLIENT_ARCH_PPC_EPAPR,              13, 'CLIENT_ARCH_PPC_EPAPR' );
    is( $CLIENT_ARCH_POWER_OPAL_V3,          14, 'CLIENT_ARCH_POWER_OPAL_V3' );
    is( $CLIENT_ARCH_X86_UEFI_HTTP,          15, 'CLIENT_ARCH_X86_UEFI_HTTP' );
    is( $CLIENT_ARCH_X64_UEFI_HTTP,          16, 'CLIENT_ARCH_X64_UEFI_HTTP' );
    is( $CLIENT_ARCH_EBC_HTTP,               17, 'CLIENT_ARCH_EBC_HTTP' );
    is( $CLIENT_ARCH_ARM_32_UEFI_HTTP,       18, 'CLIENT_ARCH_ARM_32_UEFI_HTTP' );
    is( $CLIENT_ARCH_ARM_64_UEFI_HTTP,       19, 'CLIENT_ARCH_ARM_64_UEFI_HTTP' );
    is( $CLIENT_ARCH_PC_AT_BIOS_HTTP,        20, 'CLIENT_ARCH_PC_AT_BIOS_HTTP' );
    is( $CLIENT_ARCH_ARM_32_UBOOT,           21, 'CLIENT_ARCH_ARM_32_UBOOT' );
    is( $CLIENT_ARCH_ARM_64_UBOOT,           22, 'CLIENT_ARCH_ARM_64_UBOOT' );
    is( $CLIENT_ARCH_ARM_UBOOT_32_HTTP,      23, 'CLIENT_ARCH_ARM_UBOOT_32_HTTP' );
    is( $CLIENT_ARCH_ARM_UBOOT_64_HTTP,      24, 'CLIENT_ARCH_ARM_UBOOT_64_HTTP' );
    is( $CLIENT_ARCH_RISCV_32_UEFI,          25, 'CLIENT_ARCH_RISCV_32_UEFI' );
    is( $CLIENT_ARCH_RISCV_32_UEFI_HTTP,     26, 'CLIENT_ARCH_RISCV_32_UEFI_HTTP' );
    is( $CLIENT_ARCH_RISCV_64_UEFI,          27, 'CLIENT_ARCH_RISCV_64_UEFI' );
    is( $CLIENT_ARCH_RISCV_64_UEFI_HTTP,     28, 'CLIENT_ARCH_RISCV_64_UEFI_HTTP' );
    is( $CLIENT_ARCH_RISCV_128_UEFI,         29, 'CLIENT_ARCH_RISCV_128_UEFI' );
    is( $CLIENT_ARCH_RISCV_128_UEFI_HTTP,    30, 'CLIENT_ARCH_RISCV_128_UEFI_HTTP' );
    is( $CLIENT_ARCH_S390_BASIC,             31, 'CLIENT_ARCH_S390_BASIC' );
    is( $CLIENT_ARCH_S390_EXTENDED,          32, 'CLIENT_ARCH_S390_EXTENDED' );
    is( $CLIENT_ARCH_MIPS_32_UEFI,           33, 'CLIENT_ARCH_MIPS_32_UEFI' );
    is( $CLIENT_ARCH_MIPS_64_UEFI,           34, 'CLIENT_ARCH_MIPS_64_UEFI' );
    is( $CLIENT_ARCH_SUNWAY_32_UEFI,         35, 'CLIENT_ARCH_SUNWAY_32_UEFI' );
    is( $CLIENT_ARCH_SUNWAY_64_UEFI,         36, 'CLIENT_ARCH_SUNWAY_64_UEFI' );
    is( $CLIENT_ARCH_LOONGARCH_32_UEFI,      37, 'CLIENT_ARCH_LOONGARCH_32_UEFI' );
    is( $CLIENT_ARCH_LOONGARCH_32_UEFI_HTTP, 38, 'CLIENT_ARCH_LOONGARCH_32_UEFI_HTTP' );
    is( $CLIENT_ARCH_LOONGARCH_64_UEFI,      39, 'CLIENT_ARCH_LOONGARCH_64_UEFI' );
    is( $CLIENT_ARCH_LOONGARCH_64_UEFI_HTTP, 40, 'CLIENT_ARCH_LOONGARCH_64_UEFI_HTTP' );
    is( $CLIENT_ARCH_ARM_RPIBOOT,            41, 'CLIENT_ARCH_ARM_RPIBOOT' );

    is( Net::DHCPv6::Constants::arch_name( 0 ),  'X86_BIOS',    'REV_CLIENT_ARCH 0' );
    is( Net::DHCPv6::Constants::arch_name( 41 ), 'ARM_RPIBOOT', 'REV_CLIENT_ARCH 41' );
    ok( !defined Net::DHCPv6::Constants::arch_name( 99 ), 'REV_CLIENT_ARCH 99 undef' );
};

# -------------------------------------------------------------------
# Client FQDN flags (RFC 4704 Section 4)
# -------------------------------------------------------------------
subtest 'Client FQDN flags' => sub {
    is( $CLIENT_FQDN_S, 0x01, 'CLIENT_FQDN_S' );
    is( $CLIENT_FQDN_O, 0x02, 'CLIENT_FQDN_O' );
    is( $CLIENT_FQDN_N, 0x04, 'CLIENT_FQDN_N' );
};

# -------------------------------------------------------------------
# Link-layer types (IANA ARP Hardware Type registry)
# -------------------------------------------------------------------
subtest 'Link-layer types' => sub {
    is( $LINK_TYPE_RESERVED,        0,      'LINK_TYPE_RESERVED' );
    is( $LINK_TYPE_ETHERNET,        1,      'LINK_TYPE_ETHERNET' );
    is( $LINK_TYPE_EXP_ETHERNET,    2,      'LINK_TYPE_EXP_ETHERNET' );
    is( $LINK_TYPE_AX25,            3,      'LINK_TYPE_AX25' );
    is( $LINK_TYPE_PRONET,          4,      'LINK_TYPE_PRONET' );
    is( $LINK_TYPE_CHAOS,           5,      'LINK_TYPE_CHAOS' );
    is( $LINK_TYPE_IEEE802,         6,      'LINK_TYPE_IEEE802' );
    is( $LINK_TYPE_ARCNET,          7,      'LINK_TYPE_ARCNET' );
    is( $LINK_TYPE_HYPERCHANNEL,    8,      'LINK_TYPE_HYPERCHANNEL' );
    is( $LINK_TYPE_LANSTAR,         9,      'LINK_TYPE_LANSTAR' );
    is( $LINK_TYPE_AUTONET,         10,     'LINK_TYPE_AUTONET' );
    is( $LINK_TYPE_LOCALTALK,       11,     'LINK_TYPE_LOCALTALK' );
    is( $LINK_TYPE_LOCALNET,        12,     'LINK_TYPE_LOCALNET' );
    is( $LINK_TYPE_ULTRA,           13,     'LINK_TYPE_ULTRA' );
    is( $LINK_TYPE_SMDS,            14,     'LINK_TYPE_SMDS' );
    is( $LINK_TYPE_FRAME_RELAY,     15,     'LINK_TYPE_FRAME_RELAY' );
    is( $LINK_TYPE_ATM,             16,     'LINK_TYPE_ATM' );
    is( $LINK_TYPE_HDLC,            17,     'LINK_TYPE_HDLC' );
    is( $LINK_TYPE_FIBRE_CHANNEL,   18,     'LINK_TYPE_FIBRE_CHANNEL' );
    is( $LINK_TYPE_ATM_RFC2225,     19,     'LINK_TYPE_ATM_RFC2225' );
    is( $LINK_TYPE_SERIAL,          20,     'LINK_TYPE_SERIAL' );
    is( $LINK_TYPE_ATM_ALT,         21,     'LINK_TYPE_ATM_ALT' );
    is( $LINK_TYPE_MIL_STD_188_220, 22,     'LINK_TYPE_MIL_STD_188_220' );
    is( $LINK_TYPE_METRICOM,        23,     'LINK_TYPE_METRICOM' );
    is( $LINK_TYPE_IEEE1394,        24,     'LINK_TYPE_IEEE1394' );
    is( $LINK_TYPE_MAPOS,           25,     'LINK_TYPE_MAPOS' );
    is( $LINK_TYPE_TWINAXIAL,       26,     'LINK_TYPE_TWINAXIAL' );
    is( $LINK_TYPE_EUI64,           27,     'LINK_TYPE_EUI64' );
    is( $LINK_TYPE_HIPARP,          28,     'LINK_TYPE_HIPARP' );
    is( $LINK_TYPE_ISO7816,         29,     'LINK_TYPE_ISO7816' );
    is( $LINK_TYPE_ARP_SEC,         30,     'LINK_TYPE_ARP_SEC' );
    is( $LINK_TYPE_IPSEC_TUNNEL,    31,     'LINK_TYPE_IPSEC_TUNNEL' );
    is( $LINK_TYPE_INFINIBAND,      32,     'LINK_TYPE_INFINIBAND' );
    is( $LINK_TYPE_TIA_102,         33,     'LINK_TYPE_TIA_102' );
    is( $LINK_TYPE_WIEGAND,         34,     'LINK_TYPE_WIEGAND' );
    is( $LINK_TYPE_PURE_IP,         35,     'LINK_TYPE_PURE_IP' );
    is( $LINK_TYPE_HW_EXP1,         36,     'LINK_TYPE_HW_EXP1' );
    is( $LINK_TYPE_HFI,             37,     'LINK_TYPE_HFI' );
    is( $LINK_TYPE_UNIFIED_BUS,     38,     'LINK_TYPE_UNIFIED_BUS' );
    is( $LINK_TYPE_HW_EXP2,         256,    'LINK_TYPE_HW_EXP2' );
    is( $LINK_TYPE_AETHERNET,       257,    'LINK_TYPE_AETHERNET' );
    is( $LINK_TYPE_RESERVED_HIGH,   65_535, 'LINK_TYPE_RESERVED_HIGH' );

    is( Net::DHCPv6::Constants::link_type_name( 1 ),      'ETHERNET',      'REV_LINK_TYPE 1' );
    is( Net::DHCPv6::Constants::link_type_name( 38 ),     'UNIFIED_BUS',   'REV_LINK_TYPE 38' );
    is( Net::DHCPv6::Constants::link_type_name( 256 ),    'HW_EXP2',       'REV_LINK_TYPE 256' );
    is( Net::DHCPv6::Constants::link_type_name( 65_535 ), 'RESERVED_HIGH', 'REV_LINK_TYPE 65535' );
    ok( !defined Net::DHCPv6::Constants::link_type_name( 99 ), 'REV_LINK_TYPE 99 undef' );
};

# -------------------------------------------------------------------
# Option class registration coverage -- every code in REV_OPTION_CODE
# should have either a dedicated class or be noted as Generic-fallback
# -------------------------------------------------------------------
subtest 'Option class registration' => sub {
    my %rev = %Net::DHCPv6::Constants::REV_OPTION_CODE;
    for my $code ( sort { $a <=> $b } keys %rev ) {
        if ( exists $OPTION_CLASS_CODES{$code} ) {
            pass( "Option code $code ($rev{$code}) has registered class" );
        }
        else {
            note( "$rev{$code} ($code) uses Generic fallback" );
        }
    }
};

## use critic (ValuesAndExpressions::ProhibitMagicNumbers)
done_testing;
