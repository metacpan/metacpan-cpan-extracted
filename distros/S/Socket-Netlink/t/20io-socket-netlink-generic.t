#!/usr/bin/perl -w

use strict;

use Test::More tests => 13;
use Test::HexString;

use Socket::Netlink::Generic;
use IO::Socket::Netlink::Generic;

# We'll be testing a lot using packed binary strings. Endian matters
# The strings are all written in little endian, using the following function
# to swap as appropriate
BEGIN {
   *bswap = ( pack("S", 0x1234) eq "\x12\x34" ) ? sub { reverse $_[0] }
                                                : sub { $_[0] }
}

my $genlsock = IO::Socket::Netlink::Generic->new
   or die "Cannot create Netlink::Generic socket - $!";

isa_ok( $genlsock, 'IO::Socket::Netlink::Generic', '$sock' );
isa_ok( $genlsock, 'IO::Socket::Netlink',          '$sock' );
isa_ok( $genlsock, 'IO::Socket',                   '$sock' );

# We can't necessarily know what the generic netlink's own name will be but we
# know its ID number

my $family = $genlsock->get_family_by_id( NETLINK_GENERIC );

is( ref $family, "HASH", 'get_family_by_id returns a HASH ref' );
is_deeply( [ sort keys %$family ], [qw( hdrsize id maxattr name version )], 'keys of hash' );
is( $family->{id}, NETLINK_GENERIC, 'family id' );

my $genl_name = $family->{name};

$family = $genlsock->get_family_by_name( $genl_name );

is( ref $family, "HASH", 'get_family_by_name returns a HASH ref' );

is( $family->{id},   NETLINK_GENERIC, 'family id' );
is( $family->{name}, $genl_name,      'family name' );

my $message = $genlsock->new_message(
   nlmsg_type => 30,

   cmd => 1,
   version => 2
);

isa_ok( $message, 'IO::Socket::Netlink::Generic::_Message', '$message' );

ok( $message->can( "cmd" ), '$message has ->cmd accessor' );

is_hexstr( $message->pack,
   bswap("\x14\0\0\0").bswap("\x1e\0").bswap("\0\0")."\0\0\0\0\0\0\0\0".
      "\1\2\0\0",
   '$message->pack' );

is( "$message",
    "IO::Socket::Netlink::Generic::_Message(type=30,flags=0,seq=0,pid=0,cmd=1,version=2,{0 bytes})",
    '$message STRINGified' );

