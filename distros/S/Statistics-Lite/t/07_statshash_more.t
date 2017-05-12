#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 5;

BEGIN { use_ok( 'Statistics::Lite', ':all' ); }

# statshash: a tiny bit more substantial data set

my %stats = statshash(0..10,1);
is($stats{sum},56,"call sum - hash-based");
is($stats{mean},4+2/3,"call mean - hash-based");
is($stats{variance},11+1/3,"call variance - hash-based");
is($stats{variancep},10.3+8/90,"call variancep - hash-based");

