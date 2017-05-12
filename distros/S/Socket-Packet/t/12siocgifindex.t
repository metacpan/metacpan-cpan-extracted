#!/usr/bin/perl

use strict;
use Test::More;

use Socket::Packet qw( siocgifindex siocgifname );

use Socket;

# These should work on any socket type
socket( my $sock, AF_INET, SOCK_STREAM, 0 ) or
   die "Cannot socket(AF_INET) - $!";

# We can't guarantee to know any mappings, but we can probably expect to find
# an interface somewhere in the first 256 ifindexes; most likely lo=1. If we
# find one we can at least hope it bidirectionally maps. If not, just skip

my $ifindex;
my $ifname;

foreach ( 0 .. 255 ) {
   $ifname = siocgifname( $sock, $_ );
   defined $ifname or next;

   $ifindex = $_;
   last;
}

defined $ifindex or plan skip_all => "Cannot find an interface index<->name mapping to use";

plan tests => 2;

cmp_ok( length $ifname, '>', 0, 'length($ifname) > 0' );

is( siocgifindex( $sock, $ifname ), $ifindex, "siocgifindex($ifname) is $ifindex" );
