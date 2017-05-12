#!/usr/bin/perl -w

use strict;

use Test::More tests => 11;
use Test::Identity;
use Test::Refcount;

use Net::LibAsyncNS;

# TODO: Make these neater
use constant NS_C_IN => 1;
use constant NS_T_A  => 1;

my $asyncns = Net::LibAsyncNS->new( 1 );
is_oneref( $asyncns, '$asyncns has refcount 1 initially' );

my $query = $asyncns->res_query( "localhost", NS_C_IN, NS_T_A );

ok( defined $query, '$asyncns->res_query defined' );
is_refcount( $query, 2, '$query has refcount 2' ); # One here, one internal to Net::LibAsyncNS

is_refcount( $asyncns, 2, '$asyncns has refcount 2 after ->res_query' );

is( $asyncns->getnqueries, 1, '$asyncns->getnqueries now 1' );

identical( $query->asyncns, $asyncns, '$asyncns->query is $asyncns' );

$asyncns->wait( 1 ) while !$asyncns->isdone( $query );

ok( $query->isdone, '$query->isdone true' );

my $answer = $asyncns->res_done( $query );

is_refcount( $asyncns, 2, '$asyncns still has refcount 2 after ->getaddrinfo_done' );

# localhost isn't supposed to be served over DNS. So we'll just assert that
# by now we didn't die
ok( 1, '$asyncns->res_done returns' );

is( $asyncns->getnqueries, 0, '$asyncns->getnqueries 0 at EOF' );

undef $query;

is_oneref( $asyncns, '$asyncns has refcount 1 after undef $query' );
