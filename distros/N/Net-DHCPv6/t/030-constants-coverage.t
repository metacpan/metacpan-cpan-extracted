#!/usr/bin/env perl
# ABSTRACT: Validate every constant against IANA/RFC values and verify option class coverage
use strictures 2;
use Test2::V1 -ipP;
use lib 't/lib';
use lib 'lib';

use Net::DHCPv6;
use Net::DHCPv6::Constants;
use Net::DHCPv6::OptionList;

# -------------------------------------------------------------------
# Helper: check that $OPTION_XXX constant exists, matches expected
# value, is registered in REV_OPTION_CODE, and has an option class.
# -------------------------------------------------------------------
my %OPTION_CLASS_CODES;
{
    no strict 'refs';
    %OPTION_CLASS_CODES = %Net::DHCPv6::OptionList::OPTION_CLASS;
}

sub check_option_constant {
    my ( $name, $expected, $desc ) = @_;
    ( my $short = $name ) =~ s/^OPTION_//;
    is( Net::DHCPv6::Constants::option_name( $expected ), $short, "$desc: REV_OPTION_CODE{$expected} eq $short" );
    exists $OPTION_CLASS_CODES{$expected}
        ? pass( "$desc: option class registered for code $expected" )
        : note( "$desc: no dedicated option class for code $expected (Generic OK)" );
}

# -------------------------------------------------------------------
# Message types (RFC 8415 §14)
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

    ok( Net::DHCPv6::Constants::is_valid_message_type( 1 ),   'is_valid 1' );
    ok( Net::DHCPv6::Constants::is_valid_message_type( 13 ),  'is_valid 13' );
    ok( !Net::DHCPv6::Constants::is_valid_message_type( 0 ),  'is_valid 0 false' );
    ok( !Net::DHCPv6::Constants::is_valid_message_type( 99 ), 'is_valid 99 false' );
};

# -------------------------------------------------------------------
# Option codes (RFC 8415 §21)
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
# Status codes (RFC 8415 §18.3)
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
# DUID types (RFC 8415 §11)
# -------------------------------------------------------------------
subtest 'DUID types' => sub {
    is( $DUID_LLT,  1, 'DUID_LLT' );
    is( $DUID_EN,   2, 'DUID_EN' );
    is( $DUID_LL,   3, 'DUID_LL' );
    is( $DUID_UUID, 4, 'DUID_UUID' );
};

# -------------------------------------------------------------------
# Option class registration coverage — every code in REV_OPTION_CODE
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

done_testing;
