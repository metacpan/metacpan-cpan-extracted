#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 3;
use Numeric::Matrix;

my $X = Numeric::Matrix::from_array([3, 4, 3, 4], 2, 2);
my $gamma = [1, 1];

my $Y = $X->rms_norm($gamma);

ok(ref($Y) eq 'Numeric::Matrix', 'isa Numeric::Matrix');
is($Y->rows, 2, 'result rows');
is($Y->cols, 2, 'result cols');

# RMS = sqrt(mean(x^2)) for row [3,4] = sqrt((9+16)/2) = sqrt(12.5) ≈ 3.536
# Normalized: [3/3.536, 4/3.536] ≈ [0.849, 1.131]
