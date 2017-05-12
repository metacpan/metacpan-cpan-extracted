#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Test::More;
use PerlX::Range;

my $r = 1..10;
is($r->items, 10, 'the Range has items method');

is($r->min,  1, 'the Range has min method');
is($r->max, 10, 'the range has max method');
is($r->from, 1, 'the range has from method');
is($r->to,  10, 'the range has to method');

done_testing;
