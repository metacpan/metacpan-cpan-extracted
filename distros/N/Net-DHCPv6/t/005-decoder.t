#!/usr/bin/env perl
use strictures 2;
use Test2::V1 -ipP;
use lib 't/lib';
use lib 'lib';

use Net::DHCPv6;
use Test::Net::DHCPv6;

# decode_or_croak - Solicit
my $bytes  = hex2bytes( solicit_hex() );
my $packet = Net::DHCPv6->decode_or_croak( $bytes );
ok( $packet->isa( 'Net::DHCPv6::Message::Solicit' ), 'decode_or_croak Solicit' );
is( $packet->transaction_id, 123456, 'Solicit tid from fixture' );

my $cid = $packet->get_option( 1 );
ok( $cid->isa( 'Net::DHCPv6::Option::ClientId' ), 'Solicit has ClientId' );
is( $cid->duid->time,       123456,                       'ClientId DUID time' );
is( $cid->duid->identifier, pack( 'H*', '001122334455' ), 'ClientId DUID mac' );

# decode_or_croak - Advertise
$bytes  = hex2bytes( advertise_hex() );
$packet = Net::DHCPv6->decode_or_croak( $bytes );
ok( $packet->isa( 'Net::DHCPv6::Message::Advertise' ), 'decode_or_croak Advertise' );

my $sid = $packet->get_option( 2 );
ok( $sid->isa( 'Net::DHCPv6::Option::ServerId' ), 'Advertise has ServerId' );

# decode_or_croak - Request
$bytes  = hex2bytes( request_hex() );
$packet = Net::DHCPv6->decode_or_croak( $bytes );
ok( $packet->isa( 'Net::DHCPv6::Message::Request' ), 'decode_or_croak Request' );

my $oro = $packet->get_option( 6 );
ok( $oro->isa( 'Net::DHCPv6::Option::ORO' ), 'Request has ORO' );
is( $oro->requested_options, [ 23, 24 ], 'ORO codes correct' );

# decode_or_croak - Reply with IA_NA + IAAddr
$bytes  = hex2bytes( reply_hex() );
$packet = Net::DHCPv6->decode_or_croak( $bytes );
ok( $packet->isa( 'Net::DHCPv6::Message::Reply' ), 'decode_or_croak Reply' );

my $iana = $packet->get_option( 3 );
ok( $iana->isa( 'Net::DHCPv6::Option::IANA' ), 'Reply has IANA' );
is( $iana->iaid, 42,   'IANA iaid' );
is( $iana->t1,   3600, 'IANA t1' );
is( $iana->t2,   5400, 'IANA t2' );

my $iaaddr = $iana->get_option( 5 );
ok( $iaaddr->isa( 'Net::DHCPv6::Option::IAAddr' ), 'IANA has IAAddr' );
is( $iaaddr->address,            pack( 'H*', '20010db8000000000000000000000001' ), 'IAAddr address' );
is( $iaaddr->preferred_lifetime, 7200,                                             'IAAddr preferred' );
is( $iaaddr->valid_lifetime,     86400,                                            'IAAddr valid' );

# decode_or_null - valid
$bytes  = hex2bytes( solicit_hex() );
$packet = Net::DHCPv6->decode_or_null( $bytes );
ok( defined $packet,                                 'decode_or_null returns packet for valid data' );
ok( $packet->isa( 'Net::DHCPv6::Message::Solicit' ), 'decode_or_null returns correct class' );

# decode_or_null - invalid (empty)
$packet = Net::DHCPv6->decode_or_null( '' );
ok( !defined $packet, 'decode_or_null returns undef for empty data' );

# decode_or_null - truncated
$packet = Net::DHCPv6->decode_or_null( "\x01\x02" );
ok( !defined $packet, 'decode_or_null returns undef for truncated data' );

# decode_with_error - valid
$bytes = hex2bytes( solicit_hex() );
my ( $pkt, $err ) = Net::DHCPv6->decode_with_error( $bytes );
ok( defined $pkt,  'decode_with_error returns packet for valid data' );
ok( !defined $err, 'decode_with_error no error for valid data' );

# decode_with_error - invalid
( $pkt, $err ) = Net::DHCPv6->decode_with_error( "\x01\x02" );
ok( !defined $pkt, 'decode_with_error returns undef for truncated' );
ok( defined $err,  'decode_with_error returns error for truncated' );

# Packet->new($bytes) sugar
$bytes  = hex2bytes( solicit_hex() );
$packet = Net::DHCPv6::Packet->new( $bytes );
ok( $packet->isa( 'Net::DHCPv6::Message::Solicit' ), 'Packet->new($bytes) delegates' );

# decode_or_croak on empty data
ok( dies { Net::DHCPv6->decode_or_croak( '' ) },    'decode_or_croak with empty dies' );
ok( dies { Net::DHCPv6->decode_or_croak( undef ) }, 'decode_or_croak with undef dies' );

done_testing;
