#!/usr/bin/perl

use strict;
use Test::More;

use IO::Socket::Packet;

# We can't guarantee to know any mappings, but we can probably expect to find
# an interface somewhere in the first 256 ifindexes; most likely lo=1. If we
# find one we can at least hope it bidirectionally maps. If not, just skip

my $ifindex;
my $ifname;

foreach ( 0 .. 255 ) {
   $ifname = IO::Socket::Packet->ifindex2name( $_ );
   defined $ifname or next;

   $ifindex = $_;
   last;
}

defined $ifindex or plan skip_all => "Cannot find an interface index<->name mapping to use";

plan tests => 2;

cmp_ok( length $ifname, '>', 0, 'length($ifname) > 0' );

is( IO::Socket::Packet->ifname2index( $ifname ), $ifindex, "ifname2index($ifname) is $ifindex" );
