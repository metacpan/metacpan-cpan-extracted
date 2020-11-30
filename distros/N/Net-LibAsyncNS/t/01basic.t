#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Refcount;

use Net::LibAsyncNS;

my $asyncns = Net::LibAsyncNS->new( 1 );

isa_ok( $asyncns, "Net::LibAsyncNS", '$asyncns' );
is_oneref( $asyncns, '$asyncns has refcount 1 initially' );

cmp_ok( $asyncns->fd, '>', 0, '$asyncns->fd > 0' );

isa_ok( $asyncns->new_handle_for_fd, "IO::Handle", '$asyncns->new_handle_for_fd' );

is( $asyncns->getnqueries, 0, '$asyncns->getnqueries == 0' );

ok( eval { undef $asyncns; 1 }, '$asyncns->DESTROY' );

done_testing;
