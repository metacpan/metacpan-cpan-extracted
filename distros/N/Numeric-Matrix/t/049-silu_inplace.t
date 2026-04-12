#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 3;
use Numeric::Matrix;

my $m = Numeric::Matrix::from_array([1, 2, 3, 4], 2, 2);
$m->silu_inplace;

# SiLU(x) = x * sigmoid(x) = x / (1 + exp(-x))
# For x=1: 1 / (1 + exp(-1)) ≈ 0.7311
# For x=4: 4 / (1 + exp(-4)) ≈ 3.928

ok($m->get(0, 0) > 0.7 && $m->get(0, 0) < 0.8, 'silu(1) ≈ 0.73');
ok($m->get(1, 1) > 3.9 && $m->get(1, 1) < 4.0, 'silu(4) ≈ 3.93');
ok($m->get(0, 1) > 1.7 && $m->get(0, 1) < 1.8, 'silu(2) ≈ 1.76');
