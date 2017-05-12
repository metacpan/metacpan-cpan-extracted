#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 6;

BEGIN { use_ok( 'Statistics::Lite', ':all' ); }

# unbiased sample test

my @values = (3, -10, 8, undef, 7, undef, 8, 3, 6, 3);
is(mean(@values), 3.5, "call unbiased sample set mean" );
is(median(@values), 4.5, "call unbiased sample set median" );
is(mode(@values), 3, "call unbiased sample set mode" );
is(variance(1,2,3), 1, "call unbiased sample set variance");
is(stddev(1,2,3),   1, "call unbiased sample set standard deviation");
