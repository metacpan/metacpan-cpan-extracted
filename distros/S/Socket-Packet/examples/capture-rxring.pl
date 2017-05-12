#!/usr/bin/perl

use strict;
use warnings;

use IO::Socket::Packet;
use Socket::Packet qw(
   PACKET_OUTGOING
);

my $sock = IO::Socket::Packet->new( IfIndex => 0 )
   or die "Cannot create PF_PACKET socket - $!";

unless( eval { $sock->setup_rx_ring( 2048, 128, 16384 ) } ) {
   die "Cannot setup PACKET_RX_RING - $@" if $@;
   die "Cannot setup PACKET_RX_RING - $!";
}

while( defined $sock->wait_ring_frame( my $packet, \my %info ) ) {
   my @ts = localtime $info{tp_sec};
   printf "[%4d/%02d/%02d %02d:%02d:%02d.%09d] ", $ts[5]+1900, $ts[4]+1, @ts[3,2,1,0], $info{tp_nsec};

   # Reformat nicely for printing
   my $addr = join( ":", map sprintf("%02x", ord $_), split //, $info{sll_addr} );

   if( $info{sll_pkttype} == PACKET_OUTGOING ) {
      print "Sent a packet to $addr";
   }
   else {
      print "Received a packet from $addr";
   }

   printf " of protocol %04x on %s:\n", $info{sll_protocol}, $sock->ifindex2name( $info{sll_ifindex} );

   printf "  %v02x\n", $1 while $packet =~ m/(.{1,16})/sg;

   $sock->done_ring_frame;
}
