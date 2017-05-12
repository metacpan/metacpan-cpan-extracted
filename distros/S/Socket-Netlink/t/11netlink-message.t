#!/usr/bin/perl -w

use strict;

use Test::More tests => 12;
use Test::HexString;

use Socket::Netlink qw( NLM_F_REQUEST );
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

$message->nlmsg( "" ); # empty body

is_hexstr( $message->pack,
   bswap("\x10\0\0\0")."\0\0\0\0\0\0\0\0\0\0\0\0",
   '$message->pack' );

is( "$message",
    "IO::Socket::Netlink::_Message(type=0,flags=0,seq=0,pid=0,nlmsg={0 bytes})",
    '$message STRINGified' );

$message = $sock->new_message(
   nlmsg_type  => 1,
   nlmsg_flags => 2,
   nlmsg_seq   => 100,
   nlmsg_pid   => 101,
   nlmsg       => "ABCD",
);

is_hexstr( $message->pack,
   bswap("\x14\0\0\0").bswap("\1\0").bswap("\2\0").bswap("\x64\0\0\0").bswap("\x65\0\0\0")."ABCD",
   '$message->pack with interesting fields' );

$message = $sock->unpack_message(
   bswap("\x12\0\0\0").bswap("\3\0").bswap("\4\0").bswap("\x66\0\0\0").bswap("\x67\0\0\0")."EF"
);

ok( defined $message, '$sock->unpack_message defined' );

is( $message->nlmsg_type,    3, 'nlmsg_type' );
is( $message->nlmsg_flags,   4, 'nlmsg_flags' );
is( $message->nlmsg_seq,   102, 'nlmsg_seq' );
is( $message->nlmsg_pid,   103, 'nlmsg_pid' );
is( $message->nlmsg,      "EF", 'nlmsg' );

is( "$message",
    "IO::Socket::Netlink::_Message(type=NLMSG_DONE,flags=NLM_F_ACK,seq=102,pid=103,nlmsg={2 bytes})",
    '$message STRINGified' );

$message = $sock->new_request(
   nlmsg_type  => 50,
);

is( $message->nlmsg_flags, NLM_F_REQUEST, 'nlmsg_flags set to NLM_F_REQUEST by ->new_request' );
