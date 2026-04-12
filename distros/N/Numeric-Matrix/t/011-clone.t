#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 4;
use Numeric::Matrix;

my $m = Numeric::Matrix::from_array([1, 2, 3, 4], 2, 2);
my $c = $m->clone;

ok(ref($c) eq 'Numeric::Matrix', 'isa Numeric::Matrix');
is($c->sum, $m->sum, 'same sum');
$c->set(0, 0, 100);
is($c->get(0, 0), 100, 'clone modified');
is($m->get(0, 0), 1, 'original unchanged');
