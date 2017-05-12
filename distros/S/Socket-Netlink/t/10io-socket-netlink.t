#!/usr/bin/perl -w

use strict;

use Test::More tests => 7;

use Socket qw( SOCK_RAW );
use Socket::Netlink qw( PF_NETLINK );

# We actually need some protocol implementation. NETLINK_ROUTE is 0. We'll use
# that

package Rtnetlink;
use base qw( IO::Socket::Netlink );
__PACKAGE__->register_protocol( 0 );

sub configure { shift() }

package main;

my $sock = IO::Socket::Netlink->new( Protocol =>  0 )
   or die "Cannot create Netlink socket - $!";

isa_ok( $sock, 'IO::Socket::Netlink', '$sock' );
isa_ok( $sock, 'IO::Socket',          '$sock' );

isa_ok( $sock, 'Rtnetlink', '$sock was upcast correctly' );

is( $sock->sockdomain, PF_NETLINK, '$sock->sockdomain is PF_NETLINK' );
is( $sock->socktype,   SOCK_RAW,   '$sock->socktype is SOCK_RAW' );
is( $sock->sockpid,    $$,         '$sock->sockpid is getpid()' );
is( $sock->sockgroups, 0,          '$sock->sockgroups is 0' );
