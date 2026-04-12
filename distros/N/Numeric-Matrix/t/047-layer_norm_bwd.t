#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 6;
use Numeric::Matrix;

# Forward pass
my $X = Numeric::Matrix::from_array([1, 2, 3, 4], 2, 2);
my $gamma = [1, 1];
my $beta = [0, 0];
my ($Y, $mean, $inv_std) = $X->layer_norm($gamma, $beta);

# Backward pass
my $dY = Numeric::Matrix::ones(2, 2);
my ($dX, $dgamma, $dbeta) = Numeric::Matrix::layer_norm_bwd($dY, $X, $mean, $inv_std, $gamma);

ok(ref($dX) eq 'Numeric::Matrix', 'isa Numeric::Matrix');
is($dX->rows, 2, 'dX rows');
is($dX->cols, 2, 'dX cols');

is(ref($dgamma), 'ARRAY', 'dgamma is array');
is(ref($dbeta), 'ARRAY', 'dbeta is array');
is(scalar(@$dgamma), 2, 'dgamma length');
