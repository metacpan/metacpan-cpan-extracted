#!/usr/bin/perl -w

use strict;

use Test::More tests => 8;
use Test::HexString;

use Socket::Netlink qw( NLMSG_ERROR pack_nlmsghdr unpack_nlmsghdr );
use IO::Socket::Netlink;

# We'll be testing a lot using packed binary strings. Endian matters
# The strings are all written in little endian, using the following function
# to swap as appropriate
BEGIN {
   *bswap = ( pack("S", 0x1234) eq "\x12\x34" ) ? sub { reverse $_[0] }
                                                : sub { $_[0] }
}

my $sock = IO::Socket::Netlink->new( Protocol => 0 )
   or die "Cannot create NetlinkTest socket - $!";

my $message = $sock->new_message;

isa_ok( $message, 'IO::Socket::Netlink::_Message', '$message' );

$message->nlmsg_type( NLMSG_ERROR );

isa_ok( $message, 'IO::Socket::Netlink::_ErrorMessage', '$message' );

$message->nlerr_error( 5 );
$message->nlerr_msg( pack_nlmsghdr( 10, 0, 0, 0, "" ) );

is_hexstr( $message->pack,
   bswap("\x24\0\0\0").bswap("\2\0")."\0\0\0\0\0\0\0\0\0\0".
      bswap("\xfb\xff\xff\xff").
         bswap("\x10\0\0\0").bswap("\x0a\0")."\0\0\0\0\0\0\0\0\0\0",
   '$message->pack with an error' );

$message = $sock->unpack_message(
   bswap("\x24\0\0\0").bswap("\2\0")."\0\0\0\0\0\0\0\0\0\0".
      bswap("\xfa\xff\xff\xff").
         bswap("\x10\0\0\0").bswap("\x0b\0")."\0\0\0\0\0\0\0\0\0\0",
);

ok( defined $message, '$sock->unpack_message defined' );
isa_ok( $message, 'IO::Socket::Netlink::_ErrorMessage', '$message from unpack' );

is( $message->nlmsg_type,  NLMSG_ERROR, 'nlmsg_type' );
is( $message->nlerr_error,           6, 'nlerr_error' );
is_deeply( [ unpack_nlmsghdr( $message->nlerr_msg ) ],
   [ 11, 0, 0, 0, "" ],
   'nlerr_msg' );
