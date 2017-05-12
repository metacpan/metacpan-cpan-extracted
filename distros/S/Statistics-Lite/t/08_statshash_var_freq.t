#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 7;

BEGIN { use_ok( 'Statistics::Lite', ':all' ); }

# statshash: variance and frequencies

my %stats= statshash(2,4,2,4);
ok($stats{variancep}, "call variancep - hash-based interface");
ok($stats{stddevp},   "call stddevp - hash-based interface");

%stats= frequencies(1,2,3,3);
is($stats{1}, 1, "frequencies matched correctly for 1");
is($stats{2}, 1, "frequencies matched correctly for 2");
is($stats{3}, 2, "frequencies matched correctly for 3");
is($stats{4}, undef, "frequencies matched correctly for 4");

