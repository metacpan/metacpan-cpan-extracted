#!/usr/bin/perl -w

use strict;

use Test::More tests => 9;
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

__PACKAGE__->is_header(
   data   => "nlmsg",
   fields => [qw( test_x test_y )],
   pack   => sub {   pack "SS", @_ },
   unpack => sub { unpack "SS", $_[0] },
);

sub nlmsg_string
{
   my $self = shift;
   return sprintf "test_x=%d,test_y=%d", $self->test_x, $self->test_y;
}

package main;

my $sock = NetlinkTest->new( Protocol => 0 )
   or die "Cannot create NetlinkTest socket - $!";

my $message = $sock->new_message;

isa_ok( $message, 'NetlinkTest::_Message',         '$message' );
isa_ok( $message, 'IO::Socket::Netlink::_Message', '$message' );

ok( $message->can( "test_x" ), '$message has ->test_x accessor' );
ok( $message->can( "test_y" ), '$message has ->test_y accessor' );

$message->test_x( 50 );
$message->test_y( 51 );

is_hexstr( $message->pack,
   bswap("\x14\0\0\0")."\0\0\0\0\0\0\0\0\0\0\0\0".
      bswap("\x32\0").bswap("\x33\0"),
   '$message->pack' );

is( "$message",
    "NetlinkTest::_Message(type=0,flags=0,seq=0,pid=0,test_x=50,test_y=51)",
    '$message STRINGified' );

$message = $sock->unpack_message(
   bswap("\x14\0\0\0")."\0\0\0\0\0\0\0\0\0\0\0\0".
      bswap("\x34\0").bswap("\x35\0"),
);

ok( defined $message, '$sock->unpack_message defined' );

is( $message->test_x, 52, '$message->text_x' );
is( $message->test_y, 53, '$message->test_y' );
