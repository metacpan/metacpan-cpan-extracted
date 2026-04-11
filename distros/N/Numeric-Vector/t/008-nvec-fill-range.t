#!/usr/bin/perl
use strict;
use warnings;
use Test2::Bundle::Numerical qw(:all);
use Numeric::Vector;

# Test fill_range
my $v = Numeric::Vector::zeros(10);
$v->fill_range(2, 5, 99.0);
is($v->get(0), 0, 'fill_range: index 0 unchanged');
is($v->get(1), 0, 'fill_range: index 1 unchanged');
is($v->get(2), 99, 'fill_range: index 2 filled');
is($v->get(3), 99, 'fill_range: index 3 filled');
is($v->get(4), 99, 'fill_range: index 4 filled');
is($v->get(5), 99, 'fill_range: index 5 filled');
is($v->get(6), 99, 'fill_range: index 6 filled');
is($v->get(7), 0, 'fill_range: index 7 unchanged');
is($v->get(8), 0, 'fill_range: index 8 unchanged');
is($v->get(9), 0, 'fill_range: index 9 unchanged');

# Test fill_range at start
my $v2 = Numeric::Vector::ones(5);
$v2->fill_range(0, 3, 0);
is($v2->get(0), 0, 'fill_range at start: index 0 filled');
is($v2->get(1), 0, 'fill_range at start: index 1 filled');
is($v2->get(2), 0, 'fill_range at start: index 2 filled');
is($v2->get(3), 1, 'fill_range at start: index 3 unchanged');
is($v2->get(4), 1, 'fill_range at start: index 4 unchanged');

# Test fill_range at end
my $v3 = Numeric::Vector::zeros(5);
$v3->fill_range(3, 2, 42);
is($v3->get(2), 0, 'fill_range at end: index 2 unchanged');
is($v3->get(3), 42, 'fill_range at end: index 3 filled');
is($v3->get(4), 42, 'fill_range at end: index 4 filled');

done_testing();
