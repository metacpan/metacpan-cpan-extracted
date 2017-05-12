#!/usr/bin/perl -w

use strict;

use Test::More tests => 15;
use Test::Identity;
use Test::Refcount;

use Net::LibAsyncNS;

use Socket qw( SOCK_STREAM AF_INET unpack_sockaddr_in inet_aton );

my $asyncns = Net::LibAsyncNS->new( 1 );
is_oneref( $asyncns, '$asyncns has refcount 1 initially' );

my %hints = (
   family   => AF_INET,
   socktype => SOCK_STREAM,
);
my $query = $asyncns->getaddrinfo( "localhost", "12345", \%hints );

ok( defined $query, '$asyncns->getaddrinfo defined' );
is_refcount( $query, 2, '$query has refcount 2' ); # One here, one internal to Net::LibAsyncNS

is_refcount( $asyncns, 2, '$asyncns has refcount 2 after ->getaddrinfo' );

is( $asyncns->getnqueries, 1, '$asyncns->getnqueries now 1' );

identical( $query->asyncns, $asyncns, '$asyncns->query is $asyncns' );

$asyncns->wait( 1 ) while !$asyncns->isdone( $query );

ok( $query->isdone, '$query->isdone true' );

my ( $err, @res ) = $asyncns->getaddrinfo_done( $query );

is_refcount( $asyncns, 2, '$asyncns still has refcount 2 after ->getaddrinfo_done' );

is( $err+0, 0, 'No $err from ->getaddrinfo_done' );

# Some libcs mistakenly give two identical results for "localhost"/AF_INET if
# the /etc/hosts file contains both an IPv4 and an IPv6 address.
cmp_ok( scalar @res, '>=', 1, '@res contains 1 result' );

is( $res[0]->{family},   AF_INET,     '$res[0]->{family} is AF_INET' );
is( $res[0]->{socktype}, SOCK_STREAM, '$res[0]->{socktype} is SOCK_STREAM' );

is_deeply( [ unpack_sockaddr_in $res[0]->{addr} ],
           [ 12345, inet_aton("127.0.0.1") ],
           '$res[0]->{addr} is { 12345, inet_aton("127.0.0.1") }' );

is( $asyncns->getnqueries, 0, '$asyncns->getnqueries 0 at EOF' );

undef $query;

is_oneref( $asyncns, '$asyncns has refcount 1 after undef $query' );
