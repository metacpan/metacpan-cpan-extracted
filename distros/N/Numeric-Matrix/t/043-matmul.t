#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 8;
use Numeric::Matrix;

my $A = Numeric::Matrix::from_array([1, 2, 3, 4, 5, 6], 2, 3);
my $B = Numeric::Matrix::from_array([1, 2, 3, 4, 5, 6], 3, 2);

my $C = $A->matmul($B);
ok(ref($C) eq 'Numeric::Matrix', 'isa Numeric::Matrix');
is($C->rows, 2, 'result rows');
is($C->cols, 2, 'result cols');

# [1 2 3] * [1 2]   = [22 28]
# [4 5 6]   [3 4]     [49 64]
#           [5 6]
is($C->get(0, 0), 22, 'C[0,0]');
is($C->get(0, 1), 28, 'C[0,1]');
is($C->get(1, 0), 49, 'C[1,0]');
is($C->get(1, 1), 64, 'C[1,1]');

# Identity
my $I = Numeric::Matrix::from_array([1, 0, 0, 1], 2, 2);
my $D = $C->matmul($I);
is($D->get(0, 0), 22, 'identity matmul');
