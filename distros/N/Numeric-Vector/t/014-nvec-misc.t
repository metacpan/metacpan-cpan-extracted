#!/usr/bin/env perl
# Test Numeric::Vector miscellaneous functions: get, set, round, axpy
use strict;
use warnings;
use Test2::Bundle::Numerical qw(:all);
use Numeric::Vector;

if (is_quadmath()) {
    diag("Testing with quadmath (128-bit precision)");
}

my $tol = get_tolerance();

# ============================================
# get - element access
# ============================================
subtest 'get - basic' => sub {
    my $v = Numeric::Vector::new([10, 20, 30, 40, 50]);

    is($v->get(0), 10, 'get index 0');
    is($v->get(1), 20, 'get index 1');
    is($v->get(2), 30, 'get index 2');
    is($v->get(3), 40, 'get index 3');
    is($v->get(4), 50, 'get index 4');
};

subtest 'get - boundary indices' => sub {
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);

    is($v->get(0), 1, 'get first element (index 0)');
    is($v->get(4), 5, 'get last element (index len-1)');
};

subtest 'get - float values' => sub {
    my $v = Numeric::Vector::new([1.5, 2.5, 3.5]);

    ok(approx_eq($v->get(0), 1.5, $tol), 'get float value');
    ok(approx_eq($v->get(1), 2.5, $tol), 'get float value');
    ok(approx_eq($v->get(2), 3.5, $tol), 'get float value');
};

# ============================================
# set - element assignment
# ============================================
subtest 'set - basic' => sub {
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);

    $v->set(0, 100);
    is($v->get(0), 100, 'set index 0');

    $v->set(2, 300);
    is($v->get(2), 300, 'set index 2');

    $v->set(4, 500);
    is($v->get(4), 500, 'set index 4');
};

subtest 'set - boundary indices' => sub {
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);

    $v->set(0, 99);
    is($v->get(0), 99, 'set first element');

    $v->set(4, 77);
    is($v->get(4), 77, 'set last element');
};

subtest 'set - float values' => sub {
    my $v = Numeric::Vector::new([0, 0, 0]);

    $v->set(0, 1.5);
    $v->set(1, 2.5);
    $v->set(2, 3.5);

    ok(approx_eq($v->get(0), 1.5, $tol), 'set float value 0');
    ok(approx_eq($v->get(1), 2.5, $tol), 'set float value 1');
    ok(approx_eq($v->get(2), 3.5, $tol), 'set float value 2');
};

subtest 'set - returns self for chaining' => sub {
    my $v = Numeric::Vector::new([1, 2, 3]);

    my $result = $v->set(0, 10)->set(1, 20)->set(2, 30);
    is_deeply($result->to_array, [10, 20, 30], 'chained set operations');
};

# ============================================
# round - element-wise rounding
# ============================================
subtest 'round - basic' => sub {
    my $v = Numeric::Vector::new([1.4, 1.5, 1.6, 2.4, 2.5, 2.6]);
    my $result = $v->round;

    my @vals = @{$result->to_array};
    ok(approx_eq($vals[0], 1, $tol), 'round 1.4 = 1');
    ok(approx_eq($vals[1], 2, $tol), 'round 1.5 = 2');  # Round half up
    ok(approx_eq($vals[2], 2, $tol), 'round 1.6 = 2');
    ok(approx_eq($vals[3], 2, $tol), 'round 2.4 = 2');
    ok(approx_eq($vals[4], 3, $tol) || approx_eq($vals[4], 2, $tol), 'round 2.5 = 2 or 3 (banker\'s rounding)');
    ok(approx_eq($vals[5], 3, $tol), 'round 2.6 = 3');
};

subtest 'round - negative values' => sub {
    my $v = Numeric::Vector::new([-1.4, -1.5, -1.6]);
    my $result = $v->round;

    my @vals = @{$result->to_array};
    ok(approx_eq($vals[0], -1, $tol), 'round -1.4 = -1');
    ok(approx_eq(abs($vals[1]), 2, $tol) || approx_eq(abs($vals[1]), 1, $tol), 'round -1.5');
    ok(approx_eq($vals[2], -2, $tol), 'round -1.6 = -2');
};

subtest 'round - integers unchanged' => sub {
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $result = $v->round;

    is_deeply($result->to_array, [1, 2, 3, 4, 5], 'round integers unchanged');
};

subtest 'round - near zero' => sub {
    my $v = Numeric::Vector::new([0.1, 0.4, 0.5, 0.6, 0.9]);
    my $result = $v->round;

    my @vals = @{$result->to_array};
    ok(approx_eq($vals[0], 0, $tol), 'round 0.1 = 0');
    ok(approx_eq($vals[1], 0, $tol), 'round 0.4 = 0');
    ok(approx_eq($vals[2], 1, $tol) || approx_eq($vals[2], 0, $tol), 'round 0.5');
    ok(approx_eq($vals[3], 1, $tol), 'round 0.6 = 1');
    ok(approx_eq($vals[4], 1, $tol), 'round 0.9 = 1');
};

# ============================================
# axpy - BLAS operation: y = a*x + y
# ============================================
subtest 'axpy - basic' => sub {
    my $x = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $y = Numeric::Vector::new([10, 20, 30, 40, 50]);

    # y = 2*x + y = [12, 24, 36, 48, 60]
    $y->axpy(2, $x);

    is_deeply($y->to_array, [12, 24, 36, 48, 60], 'axpy: y = 2*x + y');
};

subtest 'axpy - alpha = 1' => sub {
    my $x = Numeric::Vector::new([1, 2, 3]);
    my $y = Numeric::Vector::new([10, 20, 30]);

    # y = 1*x + y = [11, 22, 33]
    $y->axpy(1, $x);

    is_deeply($y->to_array, [11, 22, 33], 'axpy: y = x + y');
};

subtest 'axpy - alpha = 0' => sub {
    my $x = Numeric::Vector::new([100, 200, 300]);
    my $y = Numeric::Vector::new([1, 2, 3]);

    # y = 0*x + y = y unchanged
    $y->axpy(0, $x);

    is_deeply($y->to_array, [1, 2, 3], 'axpy: y = 0*x + y (unchanged)');
};

subtest 'axpy - negative alpha' => sub {
    my $x = Numeric::Vector::new([1, 2, 3]);
    my $y = Numeric::Vector::new([10, 20, 30]);

    # y = -1*x + y = [9, 18, 27]
    $y->axpy(-1, $x);

    is_deeply($y->to_array, [9, 18, 27], 'axpy: y = -x + y');
};

subtest 'axpy - fractional alpha' => sub {
    my $x = Numeric::Vector::new([2, 4, 6]);
    my $y = Numeric::Vector::new([10, 20, 30]);

    # y = 0.5*x + y = [11, 22, 33]
    $y->axpy(0.5, $x);

    my @vals = @{$y->to_array};
    ok(approx_eq($vals[0], 11, $tol), 'axpy: 0.5*2 + 10 = 11');
    ok(approx_eq($vals[1], 22, $tol), 'axpy: 0.5*4 + 20 = 22');
    ok(approx_eq($vals[2], 33, $tol), 'axpy: 0.5*6 + 30 = 33');
};

subtest 'axpy - x unchanged' => sub {
    my $x = Numeric::Vector::new([1, 2, 3]);
    my $y = Numeric::Vector::new([10, 20, 30]);

    $y->axpy(2, $x);

    is_deeply($x->to_array, [1, 2, 3], 'axpy: x is unchanged');
};

# ============================================
# Combined operations
# ============================================
subtest 'get/set loop' => sub {
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);

    for my $i (0 .. $v->len - 1) {
        my $val = $v->get($i);
        $v->set($i, $val * 2);
    }

    is_deeply($v->to_array, [2, 4, 6, 8, 10], 'get/set loop doubles values');
};

subtest 'round after arithmetic' => sub {
    my $a = Numeric::Vector::new([1.1, 2.2, 3.3]);
    my $b = Numeric::Vector::new([0.9, 0.8, 0.7]);

    my $result = $a->add($b)->round;
    is_deeply($result->to_array, [2, 3, 4], 'round after add');
};

done_testing();
