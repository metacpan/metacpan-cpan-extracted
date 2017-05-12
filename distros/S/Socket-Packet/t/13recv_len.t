#!/usr/bin/perl

use strict;
use Test::More;

# MSG_TRUNC started only works on 2.4.27 or 2.6.8 or newer
my @ver = split( m/[.-]/, do { my $ver = `uname -r`; chomp $ver; $ver } );

plan skip_all => "Kernel version too old for MSG_TRUNC - need at least 2.4.27 or 2.6.8" if
   $ver[0] < 2 or 
   $ver[0] == 2 and $ver[1] < 4 or
   $ver[0] == 2 and $ver[1] == 4 and $ver[2] < 27 or
   $ver[0] == 2 and $ver[1] == 6 and $ver[2] < 8;

plan tests => 3;

# For now write the test with normal recv to prove it breaks

use Socket::Packet qw( recv_len );

use IO::Socket::INET;

# We can't socketpair an AF_INET/SOCK_DGRAM socket, so we'll have to cheat
my $s1 = IO::Socket::INET->new( Proto => 'udp', LocalPort => 0 ) or die "Cannot socket - $!";
my $s2 = IO::Socket::INET->new( Proto => 'udp', LocalPort => 0 ) or die "Cannot socket - $!";

$s1->bind( pack_sockaddr_in( 0, INADDR_ANY ) ) or die "Cannot bind - $!";
$s2->connect( $s1->sockname ) or die "Cannot connect - $!";

$s2->syswrite( "hello there\n" );

my ( $addr, $recvlen ) = recv_len( $s1, my $buffer, 4, MSG_TRUNC );

is( $addr,    $s2->sockname, 'recv addr' );
is( $recvlen, 12,            'returned length' );
is( $buffer,  "hell",        'buffer' );
