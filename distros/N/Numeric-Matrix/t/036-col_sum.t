#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 3;
use Numeric::Matrix;

my $m = Numeric::Matrix::from_array([1, 2, 3, 4, 5, 6], 2, 3);
my $cs = $m->col_sum;

is(ref($cs), 'ARRAY', 'col_sum returns arrayref');
is(scalar(@$cs), 3, 'correct length');
is_deeply($cs, [5, 7, 9], 'correct sums');
