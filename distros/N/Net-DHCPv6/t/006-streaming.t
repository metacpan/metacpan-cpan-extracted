#!/usr/bin/env perl
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
use strictures 2;
use Test2::Tools::Exception qw( dies );
use Net::DHCPv6::Option::ServerId;
use Net::DHCPv6::Option::ClientId;
use Net::DHCPv6::DUID;
use Test2::V1 -ipP, qw(is ok like done_testing);    ## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)

use lib 't/lib';
use lib 'lib';

use Net::DHCPv6;
use Net::DHCPv6::Constants;
my $EMPTY = q();

my $mac = pack( 'H*', '001122334455' );

# --- DUID streaming helpers ----------------------------------------

# decode_duid_with_error -- full DUID-LLT
my ( $duid, $err ) =
    Net::DHCPv6->decode_duid_with_error( pack( 'n n N a*', $DUID_LLT, $LINK_TYPE_ETHERNET, 123_456, $mac ) );
ok( defined $duid, 'decode_duid_with_error full DUID-LLT returns duid' );
ok( !defined $err, 'decode_duid_with_error full DUID-LLT no error' );
is( $duid->duid_type,       $DUID_LLT,           'full DUID-LLT type' );
is( $duid->link_layer_type, $LINK_TYPE_ETHERNET, 'full DUID-LLT hwtype' );
is( $duid->time,            123_456,             'full DUID-LLT time' );
is( $duid->identifier,      $mac,                'full DUID-LLT identifier' );

# decode_duid_with_error -- partial DUID-LLT (only type + hwtype, no time)
( $duid, $err ) = Net::DHCPv6->decode_duid_with_error( pack( 'n n', $DUID_LLT, $LINK_TYPE_ETHERNET ) );
ok( defined $duid, 'partial DUID-LLT returns duid' );
ok( defined $err,  'partial DUID-LLT returns error' );
is( $duid->duid_type,       $DUID_LLT,           'partial DUID-LLT has type' );
is( $duid->link_layer_type, $LINK_TYPE_ETHERNET, 'partial DUID-LLT has hwtype' );
ok( !defined $duid->time,       'partial DUID-LLT has no time' );
ok( !defined $duid->identifier, 'partial DUID-LLT has no identifier' );
like( $err, qr/LLT/, 'error mentions LLT' );

# decode_duid_with_error -- empty
( $duid, $err ) = Net::DHCPv6->decode_duid_with_error( $EMPTY );
ok( !defined $duid, 'empty DUID returns undef' );
ok( defined $err,   'empty DUID returns error' );

# decode_duid_with_error -- undef
( $duid, $err ) = Net::DHCPv6->decode_duid_with_error( undef );
ok( !defined $duid, 'undef DUID returns undef' );
ok( defined $err,   'undef DUID returns error' );

# decode_duid_with_error -- partial DUID-EN (type only, no enterprise_number)
( $duid, $err ) = Net::DHCPv6->decode_duid_with_error( pack( 'n', 2 ) );
ok( defined $duid, 'partial DUID-EN returns duid' );
is( $duid->duid_type, $DUID_EN, 'partial DUID-EN type' );

# decode_duid_with_error -- partial DUID-UUID (type + 8 of 16 bytes)
( $duid, $err ) = Net::DHCPv6->decode_duid_with_error( pack( 'n a8', 4, chr( 0 ) x 8 ) );
ok( defined $duid, 'partial DUID-UUID returns duid' );
is( $duid->duid_type, $DUID_UUID, 'partial DUID-UUID type' );
ok( !defined $duid->identifier, 'partial DUID-UUID no identifier' );

# decode_duid_or_null -- full data
$duid = Net::DHCPv6->decode_duid_or_null( pack( 'n n N a*', $DUID_LLT, $LINK_TYPE_ETHERNET, 123_456, $mac ) );
ok( defined $duid, 'decode_duid_or_null full returns duid' );

# decode_duid_or_null -- partial (returns partial, not undef)
$duid = Net::DHCPv6->decode_duid_or_null( pack( 'n n', $DUID_LLT, $LINK_TYPE_ETHERNET ) );
ok( defined $duid, 'decode_duid_or_null partial returns duid (tolerant)' );
is( $duid->duid_type, $DUID_LLT, 'partial duid has type' );

# decode_duid_or_null -- empty (no bytes at all, returns undef)
$duid = Net::DHCPv6->decode_duid_or_null( $EMPTY );
ok( !defined $duid, 'decode_duid_or_null empty returns undef' );

# decode_duid_or_croak -- full
$duid = Net::DHCPv6->decode_duid_or_croak( pack( 'n n N a*', $DUID_LLT, $LINK_TYPE_ETHERNET, 123_456, $mac ) );
ok( defined $duid, 'decode_duid_or_croak full returns duid' );

# decode_duid_or_croak -- partial (croaks)
ok( dies { Net::DHCPv6->decode_duid_or_croak( pack( 'n n', $DUID_LLT, $LINK_TYPE_ETHERNET ) ) },
    'decode_duid_or_croak partial croaks' );

# decode_duid_or_croak -- empty (croaks)
ok( dies { Net::DHCPv6->decode_duid_or_croak( $EMPTY ) }, 'decode_duid_or_croak empty croaks' );

# --- Options streaming helpers -------------------------------------

# Build a known good options byte string
my $cid        = Net::DHCPv6::Option::ClientId->new( duid => Net::DHCPv6::DUID->new_llt( 1, 123_456, $mac ) );
my $sid        = Net::DHCPv6::Option::ServerId->new( duid => Net::DHCPv6::DUID->new_llt( 1, 123_456, $mac ) );
my $opts_bytes = $cid->as_bytes . $sid->as_bytes;

# decode_options_with_error -- full
my $ol;
( $ol, $err ) = Net::DHCPv6->decode_options_with_error( $opts_bytes );
ok( defined $ol,   'decode_options_with_error full returns OptionList' );
ok( !defined $err, 'decode_options_with_error full no error' );
is( $ol->get_option( 1 )->code, 1, 'first option code' );
is( $ol->get_option( 2 )->code, 2, 'second option code' );

# decode_options_with_error -- truncated mid-option (partial list returned)
my $truncated = substr( $opts_bytes, 0, 6 );
( $ol, $err ) = Net::DHCPv6->decode_options_with_error( $truncated );
ok( defined $ol,           'truncated options returns OptionList' );
ok( defined $err,          'truncated options returns error' );
ok( !$ol->get_option( 1 ), 'no options parsed from truncated first TLV' );

# decode_options_with_error -- truncation after first complete option
my $cid_bytes  = $cid->as_bytes;
my $truncated2 = $cid_bytes . substr( $sid->as_bytes, 0, 2 );
( $ol, $err ) = Net::DHCPv6->decode_options_with_error( $truncated2 );
ok( defined $ol,  'partial second option returns OptionList' );
ok( defined $err, 'partial second option returns error' );
is( $ol->get_option( 1 )->code, 1, 'first option still parsed' );
ok( !$ol->get_option( 2 ), 'second option not present' );

# decode_options_with_error -- empty bytes
( $ol, $err ) = Net::DHCPv6->decode_options_with_error( $EMPTY );
ok( defined $ol,   'empty options returns empty OptionList' );
ok( !defined $err, 'empty options no error' );

# decode_options_with_error -- undef
( $ol, $err ) = Net::DHCPv6->decode_options_with_error( undef );
ok( defined $ol,   'undef options returns empty OptionList' );
ok( !defined $err, 'undef options no error' );

# decode_options_or_null -- full
$ol = Net::DHCPv6->decode_options_or_null( $opts_bytes );
ok( defined $ol, 'decode_options_or_null full' );

# decode_options_or_null -- partial (tolerant, returns partial)
$ol = Net::DHCPv6->decode_options_or_null( $truncated );
ok( defined $ol, 'decode_options_or_null partial returns OptionList' );

# decode_options_or_croak -- full
$ol = Net::DHCPv6->decode_options_or_croak( $opts_bytes );
ok( defined $ol, 'decode_options_or_croak full' );

# decode_options_or_croak -- truncated (croaks)
ok( dies { Net::DHCPv6->decode_options_or_croak( $truncated ) }, 'decode_options_or_croak truncated croaks' );

## use critic (ValuesAndExpressions::ProhibitMagicNumbers)
done_testing;
