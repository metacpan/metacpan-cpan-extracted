#!/usr/bin/perl

use strict;
use warnings;

use Socket qw( SOCK_DGRAM );

use IO::Socket::Packet;
use Socket::Packet qw( pack_sockaddr_ll unpack_sockaddr_ll );

use Getopt::Long;

my $IFNAME;

GetOptions(
   'I|interface=s' => \$IFNAME
) or exit(1);

my $IP = $ARGV[0];

defined $IFNAME or die "Need --interface=NAME\n";

# Interface index - use "ip link" to see them

my $sock = IO::Socket::Packet->new( 
   Protocol => 0x0806, # ARP
   IfName   => $IFNAME,
   Type     => SOCK_DGRAM
) or die "Cannot create a PF_PACKET socket - $!";

my $broadcast_addr = pack_sockaddr_ll(
   $sock->protocol, $sock->ifindex, $sock->hatype, 0, "\xff\xff\xff\xff\xff\xff"
);

my $mac_addr = ( unpack_sockaddr_ll $sock->sockname )[4];

my $arp_request = pack(
   "n n C C n A6 A4 A6 A4",
   1, 0x800, 6, 4, 1, $mac_addr, "\0\0\0\0", "\0\0\0\0\0\0", pack("CCCC", split m/\./, $IP),
);

$sock->send( $arp_request, 0, $broadcast_addr )
   or die "Cannot send - $!";

$SIG{ALRM} = sub {
   print "Timed out; no response\n";
   exit 0;
};

alarm 5;

$sock->recv( my $arp_reply, 8192 )
   or die "Cannot receive - $!";

alarm 0;

my ( undef, undef, undef, undef, undef, $s_hw, $s_prot ) = unpack(
   "n n C C n A6 A4 A6 A4", $arp_reply
);

printf "Got ARP reply from %s at %s\n",
   join( ".", unpack( "CCCC", $s_prot ) ),
   join( ":", map { sprintf("%02x", $_) } unpack( "CCCCCC", $s_hw ) );
