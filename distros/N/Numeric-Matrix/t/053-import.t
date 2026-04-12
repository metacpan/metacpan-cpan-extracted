#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 4;
use Numeric::Matrix qw(zeros ones matmul);

# Test functional export
my $a = nmat_zeros(2, 2);
ok(ref($a) eq 'Numeric::Matrix', 'isa Numeric::Matrix');
is($a->sum, 0, 'nmat_zeros works');

my $b = nmat_ones(2, 2);
is($b->sum, 4, 'nmat_ones works');

my $c = nmat_matmul($a, $b);
is($c->sum, 0, 'nmat_matmul works');
