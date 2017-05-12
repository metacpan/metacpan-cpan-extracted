#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 11;

BEGIN { use_ok( 'Statistics::Lite', ':all' ); }

my %stats= statshash(1,2,3);

is($stats{min},    1, "call min - hash-based interface");
is($stats{max},    3, "call max - hash-based interface");
is($stats{range},  2, "call range - hash-based interface");
is($stats{sum},    6, "call sum - hash-based interface");
is($stats{count},  3, "call count - hash-based interface");
is($stats{mean},   2, "call mean - hash-based interface");
is($stats{median}, 2, "call median - hash-based interface");
is($stats{mode},   2, "call mode - hash-based interface");

is($stats{variance}, 1, "call variance - hash-based interface");
is($stats{stddev},   1, "call stddev - hash-based interface");
