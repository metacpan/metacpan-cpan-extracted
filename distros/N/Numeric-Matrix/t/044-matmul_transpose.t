#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 6;
use Numeric::Matrix;

my $A = Numeric::Matrix::from_array([1, 2, 3, 4, 5, 6], 2, 3);  # 2x3
my $B = Numeric::Matrix::from_array([1, 2, 3, 4, 5, 6], 2, 3);  # 2x3

# C = A * B^T (2x3 * 3x2 = 2x2)
my $C = $A->matmul($B, 1);
is($C->rows, 2, 'trans=1: result rows');
is($C->cols, 2, 'trans=1: result cols');
is($C->get(0, 0), 14, 'trans=1: [0,0] = 1*1+2*2+3*3');

# D = A^T * B (3x2 * 2x3 = 3x3)
my $D = $A->matmul($B, 2);
is($D->rows, 3, 'trans=2: result rows');
is($D->cols, 3, 'trans=2: result cols');
is($D->get(0, 0), 17, 'trans=2: [0,0] = 1*1+4*4');
