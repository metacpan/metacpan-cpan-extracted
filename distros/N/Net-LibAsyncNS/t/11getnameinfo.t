#!/usr/bin/perl -w

use strict;

use Test::More tests => 13;
use Test::Identity;
use Test::Refcount;

use Net::LibAsyncNS;
use Net::LibAsyncNS::Constants qw( NI_NUMERICHOST NI_NUMERICSERV );

use Socket qw( pack_sockaddr_in INADDR_LOOPBACK );

my $asyncns = Net::LibAsyncNS->new( 1 );
is_oneref( $asyncns, '$asyncns has refcount 1 initially' );

my $query = $asyncns->getnameinfo( pack_sockaddr_in( 12345, INADDR_LOOPBACK ), NI_NUMERICHOST|NI_NUMERICSERV, 1, 1 );

ok( defined $query, '$asyncns->getnameinfo defined' );
is_refcount( $query, 2, '$query has refcount 2' ); # One here, one internal to Net::LibAsyncNS

is_refcount( $asyncns, 2, '$asyncns has refcount 2 after ->getnameinfo' );

is( $asyncns->getnqueries, 1, '$asyncns->getnqueries now 1' );

identical( $query->asyncns, $asyncns, '$asyncns->query is $asyncns' );

$asyncns->wait( 1 ) while !$asyncns->isdone( $query );

ok( $query->isdone, '$query->isdone true' );

my ( $err, $host, $service ) = $asyncns->getnameinfo_done( $query );

is_refcount( $asyncns, 2, '$asyncns still has refcount 2 after ->getnameinfo_done' );

is( $err+0, 0, 'No $err from ->getnameinfo_done' );

is( $host, "127.0.0.1", '$host from ->getnameinfo_done' );
is( $service, 12345,    '$service from ->getnameinfo_done' );

is( $asyncns->getnqueries, 0, '$asyncns->getnqueries 0 at EOF' );

undef $query;

is_oneref( $asyncns, '$asyncns has refcount 1 after undef $query' );
