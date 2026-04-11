#!/usr/bin/env perl
# Test Numeric::Vector vector-vector arithmetic: add, sub, mul, div
use strict;
use warnings;
use Test2::Bundle::Numerical qw(:all);
use Numeric::Vector;

if (is_quadmath()) {
    diag("Testing with quadmath (128-bit precision)");
}

my $tol = get_tolerance();

subtest 'add - vector addition' => sub {
    my $a = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $b = Numeric::Vector::new([10, 20, 30, 40, 50]);

    my $result = $a->add($b);
    is($result->len, 5, 'add result has correct length');

    my @vals = @{$result->to_array};
    is($vals[0], 11, 'add: 1 + 10 = 11');
    is($vals[1], 22, 'add: 2 + 20 = 22');
    is($vals[2], 33, 'add: 3 + 30 = 33');
    is($vals[3], 44, 'add: 4 + 40 = 44');
    is($vals[4], 55, 'add: 5 + 50 = 55');

    # Original vectors unchanged
    is_deeply($a->to_array, [1, 2, 3, 4, 5], 'original vector a unchanged');
    is_deeply($b->to_array, [10, 20, 30, 40, 50], 'original vector b unchanged');
};

subtest 'add - negative values' => sub {
    my $a = Numeric::Vector::new([5, -3, 0, 10]);
    my $b = Numeric::Vector::new([-5, 3, 0, -10]);

    my $result = $a->add($b);
    my @vals = @{$result->to_array};
    is($vals[0], 0, 'add: 5 + -5 = 0');
    is($vals[1], 0, 'add: -3 + 3 = 0');
    is($vals[2], 0, 'add: 0 + 0 = 0');
    is($vals[3], 0, 'add: 10 + -10 = 0');
};

subtest 'add - floats' => sub {
    my $a = Numeric::Vector::new([1.5, 2.5, 3.5]);
    my $b = Numeric::Vector::new([0.5, 0.5, 0.5]);

    my $result = $a->add($b);
    my @vals = @{$result->to_array};
    ok(approx_eq($vals[0], 2.0, $tol), 'add float: 1.5 + 0.5 = 2.0');
    ok(approx_eq($vals[1], 3.0, $tol), 'add float: 2.5 + 0.5 = 3.0');
    ok(approx_eq($vals[2], 4.0, $tol), 'add float: 3.5 + 0.5 = 4.0');
};

subtest 'sub - vector subtraction' => sub {
    my $a = Numeric::Vector::new([10, 20, 30, 40, 50]);
    my $b = Numeric::Vector::new([1, 2, 3, 4, 5]);

    my $result = $a->sub($b);
    is($result->len, 5, 'sub result has correct length');

    my @vals = @{$result->to_array};
    is($vals[0], 9, 'sub: 10 - 1 = 9');
    is($vals[1], 18, 'sub: 20 - 2 = 18');
    is($vals[2], 27, 'sub: 30 - 3 = 27');
    is($vals[3], 36, 'sub: 40 - 4 = 36');
    is($vals[4], 45, 'sub: 50 - 5 = 45');
};

subtest 'sub - negative results' => sub {
    my $a = Numeric::Vector::new([1, 2, 3]);
    my $b = Numeric::Vector::new([10, 20, 30]);

    my $result = $a->sub($b);
    my @vals = @{$result->to_array};
    is($vals[0], -9, 'sub: 1 - 10 = -9');
    is($vals[1], -18, 'sub: 2 - 20 = -18');
    is($vals[2], -27, 'sub: 3 - 30 = -27');
};

subtest 'sub - self' => sub {
    my $a = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $result = $a->sub($a);

    my @vals = @{$result->to_array};
    for my $i (0..$#vals) {
        is($vals[$i], 0, "sub self: element $i is 0");
    }
};

subtest 'mul - element-wise multiplication' => sub {
    my $a = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $b = Numeric::Vector::new([2, 3, 4, 5, 6]);

    my $result = $a->mul($b);
    is($result->len, 5, 'mul result has correct length');

    my @vals = @{$result->to_array};
    is($vals[0], 2, 'mul: 1 * 2 = 2');
    is($vals[1], 6, 'mul: 2 * 3 = 6');
    is($vals[2], 12, 'mul: 3 * 4 = 12');
    is($vals[3], 20, 'mul: 4 * 5 = 20');
    is($vals[4], 30, 'mul: 5 * 6 = 30');
};

subtest 'mul - with zeros' => sub {
    my $a = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $b = Numeric::Vector::new([0, 0, 0, 0, 0]);

    my $result = $a->mul($b);
    my @vals = @{$result->to_array};
    for my $i (0..$#vals) {
        is($vals[$i], 0, "mul by zero: element $i is 0");
    }
};

subtest 'mul - negative values' => sub {
    my $a = Numeric::Vector::new([2, -3, 4, -5]);
    my $b = Numeric::Vector::new([-1, -2, 3, 4]);

    my $result = $a->mul($b);
    my @vals = @{$result->to_array};
    is($vals[0], -2, 'mul: 2 * -1 = -2');
    is($vals[1], 6, 'mul: -3 * -2 = 6');
    is($vals[2], 12, 'mul: 4 * 3 = 12');
    is($vals[3], -20, 'mul: -5 * 4 = -20');
};

subtest 'div - element-wise division' => sub {
    my $a = Numeric::Vector::new([10, 20, 30, 40, 50]);
    my $b = Numeric::Vector::new([2, 4, 5, 8, 10]);

    my $result = $a->div($b);
    is($result->len, 5, 'div result has correct length');

    my @vals = @{$result->to_array};
    ok(approx_eq($vals[0], 5, $tol), 'div: 10 / 2 = 5');
    ok(approx_eq($vals[1], 5, $tol), 'div: 20 / 4 = 5');
    ok(approx_eq($vals[2], 6, $tol), 'div: 30 / 5 = 6');
    ok(approx_eq($vals[3], 5, $tol), 'div: 40 / 8 = 5');
    ok(approx_eq($vals[4], 5, $tol), 'div: 50 / 10 = 5');
};

subtest 'div - fractional results' => sub {
    my $a = Numeric::Vector::new([1, 2, 3]);
    my $b = Numeric::Vector::new([2, 3, 4]);

    my $result = $a->div($b);
    my @vals = @{$result->to_array};
    ok(approx_eq($vals[0], 0.5, $tol), 'div: 1 / 2 = 0.5');
    ok(approx_eq($vals[1], 2/3, $tol), 'div: 2 / 3 = 0.666...');
    ok(approx_eq($vals[2], 0.75, $tol), 'div: 3 / 4 = 0.75');
};

subtest 'div - negative values' => sub {
    my $a = Numeric::Vector::new([10, -10, 10, -10]);
    my $b = Numeric::Vector::new([2, 2, -2, -2]);

    my $result = $a->div($b);
    my @vals = @{$result->to_array};
    ok(approx_eq($vals[0], 5, $tol), 'div: 10 / 2 = 5');
    ok(approx_eq($vals[1], -5, $tol), 'div: -10 / 2 = -5');
    ok(approx_eq($vals[2], -5, $tol), 'div: 10 / -2 = -5');
    ok(approx_eq($vals[3], 5, $tol), 'div: -10 / -2 = 5');
};

subtest 'operator overloading + ' => sub {
    my $a = Numeric::Vector::new([1, 2, 3]);
    my $b = Numeric::Vector::new([10, 20, 30]);

    my $result = $a + $b;
    is_deeply($result->to_array, [11, 22, 33], 'operator + works');
};

subtest 'operator overloading - ' => sub {
    my $a = Numeric::Vector::new([10, 20, 30]);
    my $b = Numeric::Vector::new([1, 2, 3]);

    my $result = $a - $b;
    is_deeply($result->to_array, [9, 18, 27], 'operator - works');
};

subtest 'operator overloading * ' => sub {
    my $a = Numeric::Vector::new([1, 2, 3]);
    my $b = Numeric::Vector::new([4, 5, 6]);

    my $result = $a * $b;
    is_deeply($result->to_array, [4, 10, 18], 'operator * works');
};

subtest 'operator overloading / ' => sub {
    my $a = Numeric::Vector::new([10, 20, 30]);
    my $b = Numeric::Vector::new([2, 4, 5]);

    my $result = $a / $b;
    my @vals = @{$result->to_array};
    ok(approx_eq($vals[0], 5, $tol), 'operator / 10/2=5');
    ok(approx_eq($vals[1], 5, $tol), 'operator / 20/4=5');
    ok(approx_eq($vals[2], 6, $tol), 'operator / 30/5=6');
};

subtest 'chained operations' => sub {
    my $a = Numeric::Vector::new([1, 2, 3]);
    my $b = Numeric::Vector::new([1, 1, 1]);
    my $c = Numeric::Vector::new([2, 2, 2]);

    # (a + b) * c
    my $result = $a->add($b)->mul($c);
    is_deeply($result->to_array, [4, 6, 8], 'chained: (a + b) * c');
};

subtest 'large vectors' => sub {
    my @data_a = map { $_ * 2 } 1..1000;
    my @data_b = map { $_ } 1..1000;

    my $a = Numeric::Vector::new(\@data_a);
    my $b = Numeric::Vector::new(\@data_b);

    my $result = $a->sub($b);
    is($result->len, 1000, 'large vector has correct length');

    # Check a few samples
    my @vals = @{$result->to_array};
    is($vals[0], 1, 'large sub: 2 - 1 = 1');
    is($vals[499], 500, 'large sub: 1000 - 500 = 500');
    is($vals[999], 1000, 'large sub: 2000 - 1000 = 1000');
};

done_testing();
