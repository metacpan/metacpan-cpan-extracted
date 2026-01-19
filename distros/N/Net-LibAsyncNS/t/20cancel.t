#!/usr/bin/perl

use v5.20;
use warnings;

use Test2::V0 0.000149;

use Net::LibAsyncNS;

use Socket qw( SOCK_STREAM AF_INET );

my $asyncns = Net::LibAsyncNS->new( 1 );
is_oneref( $asyncns, '$asyncns has refcount 1 initially' );

my %hints = (
   family   => AF_INET,
   socktype => SOCK_STREAM,
);
my $query = $asyncns->getaddrinfo( "localhost", "12345", \%hints );

is( $asyncns->getnqueries, 1, '$asyncns->getnqueries now 1' );
is_refcount( $asyncns, 2, '$asyncns has refcount 2 after ->getaddrinfo' );

$asyncns->cancel( $query );

undef $query;

is( $asyncns->getnqueries, 0, '$asyncns->getnqueries 0 after cancel' );
is_oneref( $asyncns, '$asyncns has refcount 1 after ->cancel' );

done_testing;
