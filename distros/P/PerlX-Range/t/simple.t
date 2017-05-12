#!/usr/bin/env perl
use strict;
use warnings;

use 5.010;
use PerlX::Range;
use Test::More;

diag '$a = 1..10';
my $a = 1..10;

ok($a->isa("PerlX::Range"), '$a is a PerlX::Range object');
is("$a", "1..10", '$a stringifys to "1..10"');

done_testing;
