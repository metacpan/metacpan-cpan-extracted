#!/usr/bin/perl -w

use strict;

use Test::More tests => 14;
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

__PACKAGE__->has_nlattrs(
   "nlmsg",
   byte  => [ 1, "u8" ],
   short => [ 2, "u16" ],
   long  => [ 3, "u32" ],
   str   => [ 4, "asciiz" ],
   raw   => [ 5, "raw" ],
   nest  => [ 6, "nested" ],
);

package main;

my $sock = NetlinkTest->new( Protocol => 0 )
   or die "Cannot create NetlinkTest socket - $!";

my $message = $sock->new_message;

isa_ok( $message, 'NetlinkTest::_Message',         '$message' );
isa_ok( $message, 'IO::Socket::Netlink::_Message', '$message' );

$message->nlattrs( {} ); # empty

is_hexstr( $message->pack,
   bswap("\x10\0\0\0")."\0\0\0\0\0\0\0\0\0\0\0\0",
   '$message->pack' );

# Now lets put some interesting data in it
# We can't test more than one attribute at once because we can't guarantee
# the ordering it would apply

$message->nlattrs( { byte => 1 } );
is_hexstr( $message->nlmsg,
   bswap("\5\0").bswap("\1\0").bswap("\1")."\0\0\0",
   '$message->nlmsg with byte attr' );

$message->nlattrs( { short => 23 } );
is_hexstr( $message->nlmsg,
   bswap("\6\0").bswap("\2\0").bswap("\x17\0")."\0\0",
   '$message->nlmsg with short attr' );

$message->nlattrs( { long => 456 } );
is_hexstr( $message->nlmsg,
   bswap("\x08\0").bswap("\3\0").bswap("\xc8\1\0\0"),
   '$message->nlmsg with long attr' );

$message->nlattrs( { str => "ABCDE" } );
is_hexstr( $message->nlmsg,
   bswap("\x0a\0").bswap("\4\0")."ABCDE\0\0\0",
   '$message->nlmsg with str attr' );

$message->nlattrs( { raw => "X\0Y\0Z\0" } );
is_hexstr( $message->nlmsg,
   bswap("\x0a\0").bswap("\5\0")."X\0Y\0Z\0\0\0",
   '$message->nlmsg with raw attr' );

$message->nlattrs( { nest => { byte => 20 } } );
is_hexstr( $message->nlmsg,
   bswap("\x0c\0").bswap("\6\0").
      bswap("\5\0").bswap("\1\0").bswap("\x14")."\0\0\0",
   '$message->nlmsg with nested(byte) attr' );

$message = $sock->unpack_message(
   bswap("\x48\0\0\0")."\0\0\0\0\0\0\0\0\0\0\0\0".
      bswap("\5\0").bswap("\1\0").bswap("\7")."\0\0\0".
      bswap("\6\0").bswap("\2\0").bswap("\x59\0")."\0\0".
      bswap("\x08\0").bswap("\3\0").bswap("\xf3\3\0\0").
      bswap("\x08\0").bswap("\4\0")."FGH\0".
      bswap("\x0a\0").bswap("\5\0")."X\0Y\0Z\0\0\0".
      bswap("\x0c\0").bswap("\6\0").
         bswap("\5\0").bswap("\1\0").bswap("\x15")."\0\0\0",
);

ok( defined $message, '$sock->unpack_message defined' );

is_deeply( $message->nlattrs,
   {
      byte  => 7,
      short => 89,
      long  => 1011,
      str   => "FGH",
      raw   => "X\0Y\0Z\0",
      nest  => { byte => 21 },
   },
   '$message->attrs after unpack' );

is( $message->get_nlattr( "short" ), 89, '$message->get_nlattr' );

$message->change_nlattrs( long => 4321, str => "ZYX" );

is_deeply( $message->nlattrs,
   {
      byte  => 7,
      short => 89,
      long  => 4321,
      str   => "ZYX",
      raw   => "X\0Y\0Z\0",
      nest  => { byte => 21 },
   },
   '$message->attrs after change_nlattrs' );

$message->change_nlattrs( short => undef );

is_deeply( $message->nlattrs,
   {
      byte  => 7,
      long  => 4321,
      str   => "ZYX",
      raw   => "X\0Y\0Z\0",
      nest  => { byte => 21 },
   },
   '$message->attrs after change_nlattrs to delete' );
