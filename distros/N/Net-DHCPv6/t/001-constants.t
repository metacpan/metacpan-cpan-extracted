#!/usr/bin/env perl
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
use strictures 2;
use Test2::V1 -ipP, qw(is done_testing);    ## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)

use lib 't/lib';
use lib 'lib';

use Net::DHCPv6::Constants qw(
    $ADVERTISE $CONFIRM $DECLINE $DUID_EN $DUID_LL $DUID_LLT $DUID_UUID
    $INFORMATION_REQUEST
    $OPTION_CLIENTID $OPTION_ELAPSED_TIME $OPTION_IAADDR $OPTION_IA_NA
    $OPTION_IA_PD $OPTION_IAPREFIX $OPTION_IA_TA $OPTION_ORO
    $OPTION_PREFERENCE $OPTION_RAPID_COMMIT $OPTION_SERVERID
    $OPTION_STATUS_CODE
    $REBIND $RECONFIGURE $RELAY_FORW $RELAY_REPLY $RELEASE $RENEW $REPLY
    $REQUEST $SOLICIT
    $STATUS_NO_ADDRS_AVAIL $STATUS_NO_BINDING $STATUS_NO_PREFIX_AVAIL
    $STATUS_NOT_ON_LINK $STATUS_SUCCESS $STATUS_UNSPEC_FAIL
    $STATUS_USE_MULTICAST
);
my $EMPTY = q();

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

is( $OPTION_CLIENTID,     1,  'OPTION_CLIENTID' );
is( $OPTION_SERVERID,     2,  'OPTION_SERVERID' );
is( $OPTION_IA_NA,        3,  'OPTION_IA_NA' );
is( $OPTION_IA_TA,        4,  'OPTION_IA_TA' );
is( $OPTION_IAADDR,       5,  'OPTION_IAADDR' );
is( $OPTION_ORO,          6,  'OPTION_ORO' );
is( $OPTION_PREFERENCE,   7,  'OPTION_PREFERENCE' );
is( $OPTION_ELAPSED_TIME, 8,  'OPTION_ELAPSED_TIME' );
is( $OPTION_STATUS_CODE,  13, 'OPTION_STATUS_CODE' );
is( $OPTION_RAPID_COMMIT, 14, 'OPTION_RAPID_COMMIT' );
is( $OPTION_IA_PD,        25, 'OPTION_IA_PD' );
is( $OPTION_IAPREFIX,     26, 'OPTION_IAPREFIX' );

is( $STATUS_SUCCESS,         0, 'STATUS_SUCCESS' );
is( $STATUS_UNSPEC_FAIL,     1, 'STATUS_UNSPEC_FAIL' );
is( $STATUS_NO_ADDRS_AVAIL,  2, 'STATUS_NO_ADDRS_AVAIL' );
is( $STATUS_NO_BINDING,      3, 'STATUS_NO_BINDING' );
is( $STATUS_NOT_ON_LINK,     4, 'STATUS_NOT_ON_LINK' );
is( $STATUS_USE_MULTICAST,   5, 'STATUS_USE_MULTICAST' );
is( $STATUS_NO_PREFIX_AVAIL, 6, 'STATUS_NO_PREFIX_AVAIL' );

is( $DUID_LLT,  1, 'DUID_LLT' );
is( $DUID_EN,   2, 'DUID_EN' );
is( $DUID_LL,   3, 'DUID_LL' );
is( $DUID_UUID, 4, 'DUID_UUID' );

is( Net::DHCPv6::Constants::message_type_name( 1 ),      'SOLICIT',     'REV_MESSAGE_TYPE 1' );
is( Net::DHCPv6::Constants::message_type_name( 7 ),      'REPLY',       'REV_MESSAGE_TYPE 7' );
is( Net::DHCPv6::Constants::option_name( 1 ),            'CLIENTID',    'REV_OPTION_CODE 1' );
is( Net::DHCPv6::Constants::option_name( 23 ),           'DNS_SERVERS', 'REV_OPTION_CODE 23' );
is( Net::DHCPv6::Constants::status_name( 0 ),            'SUCCESS',     'REV_STATUS_CODE 0' );
is( Net::DHCPv6::Constants::is_valid_message_type( 1 ),  1,             'is_valid_message_type 1' );
is( Net::DHCPv6::Constants::is_valid_message_type( 99 ), $EMPTY,        'is_valid_message_type 99' );
## use critic (ValuesAndExpressions::ProhibitMagicNumbers)
done_testing;
