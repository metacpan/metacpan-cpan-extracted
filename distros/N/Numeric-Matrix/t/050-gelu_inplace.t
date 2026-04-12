#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 3;
use Numeric::Matrix;

my $m = Numeric::Matrix::from_array([0, 1, 2, -1], 2, 2);
$m->gelu_inplace;

# GELU(0) = 0
# GELU(1) ≈ 0.841
# GELU(-1) ≈ -0.159

approx_eq($m->get(0, 0), 0, 1e-6, 'gelu(0) = 0');
ok($m->get(0, 1) > 0.8 && $m->get(0, 1) < 0.9, 'gelu(1) ≈ 0.84');
ok($m->get(1, 1) > -0.2 && $m->get(1, 1) < -0.1, 'gelu(-1) ≈ -0.16');
