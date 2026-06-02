#!/usr/bin/env perl
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
use strictures 2;
use Test2::Tools::Exception qw( dies );
use Test2::V1 -ipP, qw(is ok done_testing);            ## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)

use lib 't/lib';
use lib 'lib';

# Intentionally do NOT load Net::DHCPv6::OptionList here to ensure
# the circular dependency (Option -> OptionList -> Generic -> Option)
# is broken by the require inside Option::from_bytes.
use Net::DHCPv6::Option;
use Net::DHCPv6::Option::ClientId;
use Net::DHCPv6::Constants;

my $EMPTY = q();

# Option->from_bytes round-trip via Generic (unknown code)

my $payload = pack( 'H*', '01020304' );
my $tlv     = pack( 'nn', 99, CORE::length( $payload ) ) . $payload;

my ( $opt, $remain ) = Net::DHCPv6::Option->from_bytes( $tlv );

ok( $opt,                                        'from_bytes returns an option' );
ok( $opt->isa( 'Net::DHCPv6::Option::Generic' ), 'from_bytes with unknown code 99 returns Generic' );
is( $opt->code, 99,       'from_bytes option code' );
is( $opt->data, $payload, 'from_bytes option data' );

ok( defined $remain && $remain eq $EMPTY, 'from_bytes no remaining bytes' );

# from_bytes with trailing data

my $tlv2 = pack( 'nn', 1, 6 ) . pack( 'H*', '000100000100' );
my ( $opt2, $remain2 ) = Net::DHCPv6::Option->from_bytes( $tlv . $tlv2 );

ok( $opt2, 'from_bytes with trailing data returns first option' );
is( $opt2->code, 99,    'first option code from concatenated TLVs' );
is( $remain2,    $tlv2, 'remaining bytes returned correctly' );

# from_bytes dispatches to registered class for known code

my $duid_bytes   = pack( 'n', 1 ) . pack( 'n', 1 ) . pack( 'N', 123_456 ) . pack( 'H*', 'aabbccddeeff' );
my $clientid_tlv = pack( 'nn', $OPTION_CLIENTID, CORE::length( $duid_bytes ) ) . $duid_bytes;
my ( $opt3, $remain3 ) = Net::DHCPv6::Option->from_bytes( $clientid_tlv );
ok( $opt3,                                         'from_bytes for ClientId returns option' );
ok( $opt3->isa( 'Net::DHCPv6::Option::ClientId' ), 'from_bytes dispatches to ClientId class' );
is( $remain3, $EMPTY, 'no remaining bytes after ClientId' );

# from_bytes dies on truncated data

ok( dies { Net::DHCPv6::Option->from_bytes( pack( 'n', 1 ) ) },      'from_bytes with less than 4 bytes dies' );
ok( dies { Net::DHCPv6::Option->from_bytes( pack( 'nn', 1, 10 ) ) }, 'from_bytes with truncated payload dies' );
ok( dies { Net::DHCPv6::Option->from_bytes( undef ) },               'from_bytes with undef dies' );

done_testing();
