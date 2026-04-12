#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 3;
use Numeric::Matrix;

my $m = Numeric::Matrix::from_array([1, 2, 3, 4, 5, 6], 2, 3);
my $rs = $m->row_sum;

is(ref($rs), 'ARRAY', 'row_sum returns arrayref');
is(scalar(@$rs), 2, 'correct length');
is_deeply($rs, [6, 15], 'correct sums');
