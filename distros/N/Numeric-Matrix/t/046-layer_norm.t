#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 6;
use Numeric::Matrix;

my $X = Numeric::Matrix::from_array([1, 2, 3, 4], 2, 2);
my $gamma = [1, 1];
my $beta = [0, 0];

my ($Y, $mean, $inv_std) = $X->layer_norm($gamma, $beta);

ok(ref($Y) eq 'Numeric::Matrix', 'isa Numeric::Matrix');
is($Y->rows, 2, 'result rows');
is($Y->cols, 2, 'result cols');

is(ref($mean), 'ARRAY', 'mean is arrayref');
is(scalar(@$mean), 2, 'mean length');

# Each row should be normalized to mean 0, std 1
# row 0: [1, 2] -> mean=1.5 -> normalized and gamma=1, beta=0
# After normalization, sum should be close to 0
my $row0_sum = $Y->get(0,0) + $Y->get(0,1);
approx_eq($row0_sum, 0, 1e-10, 'normalized row 0 sums to ~0');
