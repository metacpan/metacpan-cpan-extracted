#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 3;
use Numeric::Matrix;

my $m = Numeric::Matrix::from_array([1, 2, 3, 4, 5, 6], 2, 3);
my $a = $m->to_array;

is(ref($a), 'ARRAY', 'returns arrayref');
is(scalar(@$a), 6, 'correct length');
is_deeply($a, [1, 2, 3, 4, 5, 6], 'values match row-major');
