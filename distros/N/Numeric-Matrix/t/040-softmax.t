#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 3;
use Numeric::Matrix;

# Test softmax inplace
my $m = Numeric::Matrix::from_array([1, 2, 3, 4], 2, 2);
$m->softmax_rows_inplace;

# Each row should sum to 1
my $row0 = $m->get(0, 0) + $m->get(0, 1);
my $row1 = $m->get(1, 0) + $m->get(1, 1);

approx_eq($row0, 1.0, 1e-10, 'row 0 sums to 1');
approx_eq($row1, 1.0, 1e-10, 'row 1 sums to 1');

# Higher values should have higher probabilities
ok($m->get(0, 1) > $m->get(0, 0), 'higher input -> higher prob');
