#!/usr/bin/env perl
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
use strictures 2;
use Test2::Tools::Exception qw( dies lives );
use Test2::V1 -ipP, qw(is ok done_testing);            ## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)

use lib 't/lib';
use lib 'lib';

use Net::DHCPv6::DUID;
use Net::DHCPv6::Constants;

ok( dies { Net::DHCPv6::DUID->new },                           'new() without args dies' );
ok( dies { Net::DHCPv6::DUID->new( duid_type => $DUID_LLT ) }, 'DUID-LLT without hwtype dies' );
ok( lives { Net::DHCPv6::DUID->new_llt( $LINK_TYPE_ETHERNET, 123_456, pack( 'H*', '001122334455' ) ) },
    'new_llt lives' );

# DUID-LLT round-trip
my $mac  = pack( 'H*', '001122334455' );
my $duid = Net::DHCPv6::DUID->new_llt( $LINK_TYPE_ETHERNET, 123_456, $mac );
is( $duid->duid_type,       $DUID_LLT,           'LLT duid_type' );
is( $duid->link_layer_type, $LINK_TYPE_ETHERNET, 'LLT hwtype' );
is( $duid->time,            123_456,             'LLT time' );
is( $duid->identifier,      $mac,                'LLT identifier' );

my $bytes = $duid->as_bytes;
my $got   = Net::DHCPv6::DUID->from_bytes( $bytes );
is( $got->duid_type,       $DUID_LLT,           'parse LLT duid_type' );
is( $got->link_layer_type, $LINK_TYPE_ETHERNET, 'parse LLT hwtype' );
is( $got->time,            123_456,             'parse LLT time' );
is( $got->identifier,      $mac,                'parse LLT identifier' );

# DUID-EN round-trip
my $en_id = pack( 'H*', 'aabbccdd' );
my $en    = Net::DHCPv6::DUID->new_en( 32_473, $en_id );
is( $en->enterprise_number, 32_473, 'EN enterprise_number' );
$bytes = $en->as_bytes;
$got   = Net::DHCPv6::DUID->from_bytes( $bytes );
is( $got->enterprise_number, 32_473, 'parse EN enterprise_number' );
is( $got->identifier,        $en_id, 'parse EN identifier' );

# DUID-LL round-trip
my $ll = Net::DHCPv6::DUID->new_ll( $LINK_TYPE_IEEE802, $mac );
is( $ll->link_layer_type, $LINK_TYPE_IEEE802, 'LL hwtype' );
$bytes = $ll->as_bytes;
$got   = Net::DHCPv6::DUID->from_bytes( $bytes );
is( $got->link_layer_type, $LINK_TYPE_IEEE802, 'parse LL hwtype' );
is( $got->identifier,      $mac,               'parse LL identifier' );

# DUID-UUID round-trip
my $uuid_bytes = pack( 'H*', '00112233445566778899aabbccddeeff' );
my $uuid       = Net::DHCPv6::DUID->new_uuid( $uuid_bytes );
is( $uuid->duid_type, $DUID_UUID, 'UUID duid_type' );
$bytes = $uuid->as_bytes;
$got   = Net::DHCPv6::DUID->from_bytes( $bytes );
is( $got->identifier, $uuid_bytes, 'parse UUID identifier' );

ok( dies { Net::DHCPv6::DUID->new_uuid( 'short' ) }, 'UUID with short id dies' );

# as_string
my $str = $duid->as_string;
ok( $str =~ m/^DUID_LLT:/, 'as_string format' );

# Unknown DUID type
my $unknown = Net::DHCPv6::DUID->new( duid_type => 99, identifier => pack( 'H*', '0102' ) );
$bytes = $unknown->as_bytes;
$got   = Net::DHCPv6::DUID->from_bytes( $bytes );
is( $got->duid_type, 99, 'unknown DUID type preserved' );

# DUID::length
is( $duid->length,    14, 'LLT duid length' );
is( $en->length,      10, 'EN duid length' );
is( $ll->length,      10, 'LL duid length' );
is( $uuid->length,    18, 'UUID duid length' );
is( $unknown->length, 4,  'unknown DUID length' );

## use critic (ValuesAndExpressions::ProhibitMagicNumbers)
done_testing;
