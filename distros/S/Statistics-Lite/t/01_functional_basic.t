#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 11;

BEGIN { use_ok( 'Statistics::Lite', ':all' ); }

# Basic functional interface

is(min(1,2,3),    1, "call min - functional interface");
is(max(1,2,3),    3, "call max - functional interface");
is(range(1,2,3),  2, "call range - functional interface");
is(sum(1,2,3),    6, "call sum - functional interface");
is(count(1,2,3),  3, "call count - functional interface");
is(count(undef,1,2,3), 3, "call count with undef - functional interface");
is(mean(1,2,3),   2, "call mean - functional interface");
is(median(1,2,3), 2, "call median - functional interface");
is(median(2,4,6,8), 5, "call median with even number of values - functional interface");
is(mode(1,2,3),   2, "call mode - functional interface");
