#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 8;
use Numeric::Matrix;

my $a = Numeric::Matrix::from_array([1, 2, 3, 4, 5, 6], 2, 3);
my $b = Numeric::Matrix::from_array([1, 2, 3, 4, 5, 6], 3, 2);

my $c = $a->matmul($b);
ok(ref($c) eq 'Numeric::Matrix', 'isa Numeric::Matrix');
is($c->rows, 2, 'result rows');
is($c->cols, 2, 'result cols');

# [1 2 3] * [1 2]   = [1*1+2*3+3*5  1*2+2*4+3*6] = [22 28]
# [4 5 6]   [3 4]     [4*1+5*3+6*5  4*2+5*4+6*6] = [49 64]
#           [5 6]
is($c->get(0, 0), 22, 'c[0,0]');
is($c->get(0, 1), 28, 'c[0,1]');
is($c->get(1, 0), 49, 'c[1,0]');
is($c->get(1, 1), 64, 'c[1,1]');

# Identity multiply
my $I = Numeric::Matrix::from_array([1, 0, 0, 1], 2, 2);
my $d = $c->matmul($I);
is($d->get(0, 0), 22, 'identity multiply');
