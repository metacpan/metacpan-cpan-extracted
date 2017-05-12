#!/usr/bin/perl -w

use strict;

use Test::More tests => 4;
use Test::HexString;

# We'll be testing a lot using packed binary strings. Endian matters
# The strings are all written in little endian, using the following function
# to swap as appropriate
BEGIN {
   *bswap = ( pack("S", 0x1234) eq "\x12\x34" ) ? sub { reverse $_[0] }
                                                : sub { $_[0] }
}

package NetlinkTest;
use base qw( IO::Socket::Netlink );

sub message_class { "NetlinkTest::_Message" }

package NetlinkTest::_Message;
use base qw( IO::Socket::Netlink::_Message );

__PACKAGE__->is_subclassed_by_type;

package NetlinkTest::_RedMessage;
use base qw( NetlinkTest::_Message );

__PACKAGE__->register_nlmsg_type( 10 );

package NetlinkTest::_BlueMessage;
use base qw( NetlinkTest::_Message );

__PACKAGE__->register_nlmsg_type( 20 );

package main;

my $sock = NetlinkTest->new( Protocol => 0 )
   or die "Cannot create NetlinkTest socket - $!";

my $message = $sock->new_message;

isa_ok( $message, 'NetlinkTest::_Message',         '$message' );
isa_ok( $message, 'IO::Socket::Netlink::_Message', '$message' );

$message->nlmsg_type( 10 );

isa_ok( $message, 'NetlinkTest::_RedMessage', '$message' );

$message = $sock->unpack_message(
   bswap("\x10\0\0\0").bswap("\x14\0")."\0\0\0\0\0\0\0\0\0\0"
);

isa_ok( $message, 'NetlinkTest::_BlueMessage', '$message' );
