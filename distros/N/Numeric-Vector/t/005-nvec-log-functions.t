#!/usr/bin/perl
use strict;
use warnings;
use Test2::Bundle::Numerical qw(:all);
use Numeric::Vector;

# Test log10 and log2
my $v = Numeric::Vector::new([1, 10, 100, 1000]);

# log10 tests
my $log10_result = $v->log10();
ok(abs($log10_result->get(0) - 0) < 0.0001, 'log10(1) = 0');
ok(abs($log10_result->get(1) - 1) < 0.0001, 'log10(10) = 1');
ok(abs($log10_result->get(2) - 2) < 0.0001, 'log10(100) = 2');
ok(abs($log10_result->get(3) - 3) < 0.0001, 'log10(1000) = 3');

# log2 tests
my $v2 = Numeric::Vector::new([1, 2, 4, 8, 16]);
my $log2_result = $v2->log2();
ok(abs($log2_result->get(0) - 0) < 0.0001, 'log2(1) = 0');
ok(abs($log2_result->get(1) - 1) < 0.0001, 'log2(2) = 1');
ok(abs($log2_result->get(2) - 2) < 0.0001, 'log2(4) = 2');
ok(abs($log2_result->get(3) - 3) < 0.0001, 'log2(8) = 3');
ok(abs($log2_result->get(4) - 4) < 0.0001, 'log2(16) = 4');

done_testing();
