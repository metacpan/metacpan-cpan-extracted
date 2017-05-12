#!/usr/bin/perl -w

use strict;

use Test::More;

use Socket qw( SOCK_RAW );
use Socket::Packet qw( PF_PACKET ETH_P_ALL );

use POSIX qw( ENOENT );

# Only root can create PF_PACKET sockets. Check if we can. If not, skip all
unless( socket( my $dummy, PF_PACKET, SOCK_RAW, 0 ) ) {
   plan skip_all => "Cannot create PF_PACKET socket";
}

plan tests => 20;

require IO::Socket::Packet;

my $sock = IO::Socket::Packet->new(
   # Have to give at least one arg so it will ->configure
   IfIndex => 0,
);

isa_ok( $sock, 'IO::Socket::Packet', '$sock isa IO::Socket::Packet' );
isa_ok( $sock, 'IO::Socket',         '$sock isa IO::Socket' );

is( $sock->sockdomain, PF_PACKET, '$sock->sockdomain is PF_PACKET' );
is( $sock->socktype,   SOCK_RAW,  '$sock->socktype is SOCK_RAW' );
is( $sock->protocol,   ETH_P_ALL, '$sock->protocol is ETH_P_ALL' );
is( $sock->ifindex,    0,         '$sock->ifindex is 0' );
is( $sock->hatype,     0,         '$sock->hatype is 0' );

my ( $stamp, $errno );
$stamp = $sock->timestamp; $errno = $!+0;
is( $stamp, undef,  '$sock->stamp returns undef' );
is( $errno, ENOENT, '$sock->stamp fails with ENOENT' );

# Hopefully we've got at least one interface on this machine, "lo" if nothing
# else. Probably its index is 1. Be prepared to cope if not though

my $ifname;

SKIP: {
   my $sock = IO::Socket::Packet->new( IfIndex => 1 );

   skip 5, "Cannot bind to ifindex=1" unless $sock;

   is( $sock->sockdomain, PF_PACKET, '$sock->sockdomain is PF_PACKET' );
   is( $sock->socktype,   SOCK_RAW,  '$sock->socktype is SOCK_RAW' );
   is( $sock->protocol,   ETH_P_ALL, '$sock->protocol is ETH_P_ALL' );
   is( $sock->ifindex,    1,         '$sock->ifindex is 1' );
   # Can't easily predict what hatype it will have, but it ought not be 0
   ok( $sock->hatype != 0,           '$sock->hatype is not 0' );

   ok( defined $sock->ifname,        '$sock->ifname defined' );

   $ifname = $sock->ifname;
}

SKIP: {
   skip "No usable interface name found", 2 unless defined $ifname;

   my $sock = IO::Socket::Packet->new( IfName => $ifname );

   ok( defined $sock, 'IO::Socket::Packet->new( IfName => name ) yields a socket' );
   is( $sock->ifname, $ifname, '$sock->ifname is name' );
}

SKIP: {
   skip "IO::Socket::Packet->origdev is not supported on this platform", 2 unless defined &IO::Socket::Packet::origdev;

   ok( $sock->origdev( 1 ), '$sock->origdev works to set' );
   is( $sock->origdev, 1, '$sock->origdev works to retrieve' );
}

is_deeply( [ sort keys %{ $sock->statistics } ], [qw( drops packets )], '$sock->statistics' );
