#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 4;
use Numeric::Matrix;

my $m = Numeric::Matrix::ones(2, 3);
my $v = [10, 20, 30];
my $r = $m->add_vec_rows($v);

ok(ref($r) eq 'Numeric::Matrix', 'isa Numeric::Matrix');
is($r->get(0, 0), 11, 'first row, first col');
is($r->get(0, 2), 31, 'first row, last col');
is($r->get(1, 1), 21, 'second row, middle col');
