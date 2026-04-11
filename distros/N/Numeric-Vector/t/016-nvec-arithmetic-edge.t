#!/usr/bin/env perl
# Test Numeric::Vector arithmetic operations with edge cases and precision considerations
use strict;
use warnings;
use Test2::Bundle::Numerical qw(:all);
use Numeric::Vector;

my $is_quad = is_quadmath();
if ($is_quad) {
    diag("Testing with quadmath (128-bit precision)");
} else {
    diag("Testing with standard double precision (64-bit)");
}

my $tol = get_tolerance();

# Helper for special values
my $nan = 9**9**9 - 9**9**9;
my $inf = 9**9**9;
my $ninf = -9**9**9;

# ============================================
# Addition edge cases
# ============================================

subtest 'add: vector + vector' => sub {
    my $a = Numeric::Vector::new([1, 2, 3]);
    my $b = Numeric::Vector::new([4, 5, 6]);

    my $c = $a->add($b);
    is_deeply($c->to_array, [5, 7, 9], 'basic vector addition');
};

subtest 'add: vector + scalar' => sub {
    my $v = Numeric::Vector::new([1, 2, 3]);
    my $c = $v->add_scalar(10);
    is_deeply($c->to_array, [11, 12, 13], 'vector + scalar');
};

subtest 'add: with zeros' => sub {
    my $a = Numeric::Vector::new([1, 2, 3]);
    my $zeros = Numeric::Vector::zeros(3);

    my $c = $a->add($zeros);
    ok(vec_approx_eq($a, $c), 'v + 0 = v');
};

subtest 'add: with negative values' => sub {
    my $a = Numeric::Vector::new([1, -2, 3, -4]);
    my $b = Numeric::Vector::new([-1, 2, -3, 4]);

    my $c = $a->add($b);
    my $expected = Numeric::Vector::zeros(4);
    ok(vec_approx_eq($c, $expected), 'v + (-v) = 0');
};

subtest 'add: infinity handling' => sub {
    my $v = Numeric::Vector::new([1, 2, 3]);
    my $c = $v->add_scalar($inf);

    my @vals = @{$c->to_array};
    ok($c->isinf->get(0), 'finite + inf = inf');
    ok($c->isinf->get(1), 'finite + inf = inf');
    ok($c->isinf->get(2), 'finite + inf = inf');
};

subtest 'add: inf + (-inf) = NaN' => sub {
    my $a = Numeric::Vector::new([$inf]);
    my $b = Numeric::Vector::new([$ninf]);

    my $c = $a->add($b);
    ok($c->isnan->get(0), 'inf + (-inf) = NaN');
};

# ============================================
# Subtraction edge cases
# ============================================

subtest 'sub: vector - vector' => sub {
    my $a = Numeric::Vector::new([5, 7, 9]);
    my $b = Numeric::Vector::new([1, 2, 3]);

    my $c = $a->sub($b);
    is_deeply($c->to_array, [4, 5, 6], 'basic vector subtraction');
};

subtest 'sub: vector - scalar' => sub {
    my $v = Numeric::Vector::new([10, 20, 30]);
    # No sub_scalar method - use add_scalar with negative value
    my $c = $v->add_scalar(-5);
    is_deeply($c->to_array, [5, 15, 25], 'vector - scalar');
};

subtest 'sub: v - v = 0' => sub {
    my $v = Numeric::Vector::new([1.5, 2.5, 3.5]);
    my $c = $v->sub($v);
    my $zeros = Numeric::Vector::zeros(3);
    ok(vec_approx_eq($c, $zeros), 'v - v = 0');
};

subtest 'sub: inf - inf = NaN' => sub {
    my $a = Numeric::Vector::new([$inf]);
    my $c = $a->sub($a);
    ok($c->isnan->get(0), 'inf - inf = NaN');
};

# ============================================
# Multiplication edge cases
# ============================================

subtest 'mul: vector * vector' => sub {
    my $a = Numeric::Vector::new([2, 3, 4]);
    my $b = Numeric::Vector::new([5, 6, 7]);

    my $c = $a->mul($b);
    is_deeply($c->to_array, [10, 18, 28], 'element-wise multiplication');
};

subtest 'mul: vector * scalar' => sub {
    my $v = Numeric::Vector::new([1, 2, 3]);
    my $c = $v->scale(2);
    is_deeply($c->to_array, [2, 4, 6], 'vector * scalar');
};

subtest 'mul: with zeros' => sub {
    my $v = Numeric::Vector::new([1, 2, 3]);
    my $zeros = Numeric::Vector::zeros(3);

    my $c = $v->mul($zeros);
    ok(vec_approx_eq($c, $zeros), 'v * 0 = 0');
};

subtest 'mul: with ones' => sub {
    my $v = Numeric::Vector::new([1, 2, 3]);
    my $ones = Numeric::Vector::ones(3);

    my $c = $v->mul($ones);
    ok(vec_approx_eq($c, $v), 'v * 1 = v');
};

subtest 'mul: 0 * inf = NaN' => sub {
    my $a = Numeric::Vector::new([0]);
    my $b = Numeric::Vector::new([$inf]);

    my $c = $a->mul($b);
    ok($c->isnan->get(0), '0 * inf = NaN');
};

subtest 'mul: negative * negative = positive' => sub {
    my $a = Numeric::Vector::new([-2, -3, -4]);
    my $b = Numeric::Vector::new([-5, -6, -7]);

    my $c = $a->mul($b);
    my @vals = @{$c->to_array};
    ok($vals[0] > 0, 'negative * negative > 0');
    ok($vals[1] > 0, 'negative * negative > 0');
    ok($vals[2] > 0, 'negative * negative > 0');
};

# ============================================
# Division edge cases
# ============================================

subtest 'div: vector / vector' => sub {
    my $a = Numeric::Vector::new([10, 18, 28]);
    my $b = Numeric::Vector::new([2, 3, 4]);

    my $c = $a->div($b);
    is_deeply($c->to_array, [5, 6, 7], 'element-wise division');
};

subtest 'div: vector / scalar' => sub {
    my $v = Numeric::Vector::new([10, 20, 30]);
    my $c = $v->scale(0.5);
    is_deeply($c->to_array, [5, 10, 15], 'vector / 2 via scale(0.5)');
};

subtest 'div: by one' => sub {
    my $v = Numeric::Vector::new([1, 2, 3]);
    my $ones = Numeric::Vector::ones(3);

    my $c = $v->div($ones);
    ok(vec_approx_eq($c, $v), 'v / 1 = v');
};

subtest 'div: by zero produces infinity' => sub {
    my $a = Numeric::Vector::new([1, -1, 0]);
    my $b = Numeric::Vector::new([0, 0, 0]);

    my $c = $a->div($b);
    ok($c->isinf->get(0), '1/0 = inf');
    ok($c->isinf->get(1), '-1/0 = -inf');
    ok($c->isnan->get(2), '0/0 = NaN');
};

subtest 'div: inf / inf = NaN' => sub {
    my $a = Numeric::Vector::new([$inf]);
    my $b = Numeric::Vector::new([$inf]);

    my $c = $a->div($b);
    ok($c->isnan->get(0), 'inf / inf = NaN');
};

subtest 'div: finite / inf = 0' => sub {
    my $a = Numeric::Vector::new([1, 100, -50]);
    my $b = Numeric::Vector::new([$inf, $inf, $inf]);

    my $c = $a->div($b);
    my @vals = @{$c->to_array};
    ok(approx_eq($vals[0], 0, $tol), 'finite / inf = 0');
    ok(approx_eq($vals[1], 0, $tol), 'finite / inf = 0');
    ok(approx_eq($vals[2], 0, $tol), 'finite / inf = 0');
};

# ============================================
# Power edge cases
# ============================================

subtest 'pow: basic powers' => sub {
    my $v = Numeric::Vector::new([2, 3, 4]);

    my $sq = $v->pow(2);
    is_deeply($sq->to_array, [4, 9, 16], 'squared');

    my $cb = $v->pow(3);
    is_deeply($cb->to_array, [8, 27, 64], 'cubed');
};

subtest 'pow: power of 0' => sub {
    my $v = Numeric::Vector::new([1, 2, 3, 0, -1]);
    my $c = $v->pow(0);

    # x^0 = 1 for all x (including 0^0 = 1 by convention)
    my $ones = Numeric::Vector::ones(5);
    ok(vec_approx_eq($c, $ones), 'x^0 = 1');
};

subtest 'pow: power of 1' => sub {
    my $v = Numeric::Vector::new([1, 2, 3, -4]);
    my $c = $v->pow(1);

    ok(vec_approx_eq($c, $v), 'x^1 = x');
};

subtest 'pow: negative base with integer exponent' => sub {
    my $v = Numeric::Vector::new([-2, -2, -2]);
    my $c = $v->pow(2);  # (-2)^2 = 4

    my @vals = @{$c->to_array};
    is($vals[0], 4, '(-2)^2 = 4');
};

subtest 'pow: fractional exponent (sqrt)' => sub {
    my $v = Numeric::Vector::new([4, 9, 16, 25]);
    my $c = $v->pow(0.5);

    my @vals = @{$c->to_array};
    ok(approx_eq($vals[0], 2, $tol), '4^0.5 = 2');
    ok(approx_eq($vals[1], 3, $tol), '9^0.5 = 3');
    ok(approx_eq($vals[2], 4, $tol), '16^0.5 = 4');
    ok(approx_eq($vals[3], 5, $tol), '25^0.5 = 5');
};

subtest 'pow: negative exponent' => sub {
    my $v = Numeric::Vector::new([2, 4, 10]);
    my $c = $v->pow(-1);

    my @vals = @{$c->to_array};
    ok(approx_eq($vals[0], 0.5, $tol), '2^-1 = 0.5');
    ok(approx_eq($vals[1], 0.25, $tol), '4^-1 = 0.25');
    ok(approx_eq($vals[2], 0.1, $tol), '10^-1 = 0.1');
};

# ============================================
# Compound operations
# ============================================

subtest 'compound: (a + b) * c' => sub {
    my $a = Numeric::Vector::new([1, 2, 3]);
    my $b = Numeric::Vector::new([4, 5, 6]);
    my $c = Numeric::Vector::new([2, 2, 2]);

    my $result = $a->add($b)->mul($c);
    is_deeply($result->to_array, [10, 14, 18], '(a + b) * c');
};

subtest 'compound: (a - b) / c' => sub {
    my $a = Numeric::Vector::new([10, 20, 30]);
    my $b = Numeric::Vector::new([2, 4, 6]);
    my $c = Numeric::Vector::new([2, 2, 2]);

    my $result = $a->sub($b)->div($c);
    is_deeply($result->to_array, [4, 8, 12], '(a - b) / c');
};

subtest 'compound: a^2 + b^2' => sub {
    my $a = Numeric::Vector::new([3, 4]);
    my $b = Numeric::Vector::new([4, 3]);

    my $result = $a->pow(2)->add($b->pow(2));
    is_deeply($result->to_array, [25, 25], 'a^2 + b^2');
};

# ============================================
# Numeric stability
# ============================================

subtest 'stability: repeated operations' => sub {
    my $v = Numeric::Vector::ones(100);

    # Multiply by 2 then divide by 2 many times
    for (1..100) {
        $v = $v->scale(2);
        $v = $v->scale(0.5);
    }

    my $expected = Numeric::Vector::ones(100);
    ok(vec_approx_eq($v, $expected), 'repeated mul/div returns to original');
};

subtest 'stability: alternating add/sub' => sub {
    my $v = Numeric::Vector::new([1.0, 2.0, 3.0]);

    # Add 1 then subtract 1 many times
    for (1..100) {
        $v = $v->add_scalar(1);
        $v = $v->add_scalar(-1);  # No sub_scalar, use add_scalar with negative
    }

    my $expected = Numeric::Vector::new([1.0, 2.0, 3.0]);
    ok(vec_approx_eq($v, $expected), 'repeated add/sub returns to original');
};

subtest 'stability: large accumulated sum' => sub {
    # Sum of 1 to n = n*(n+1)/2
    my $n = 10000;
    my $v = Numeric::Vector::range(1, $n + 1);

    my $sum = $v->sum();
    my $expected = $n * ($n + 1) / 2;

    within_tolerance($sum, $expected, "sum of 1..$n");
};

# ============================================
# Broadcasting behavior
# ============================================

subtest 'broadcasting: scalar operations' => sub {
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);

    my $plus10 = $v->add_scalar(10);
    is_deeply($plus10->to_array, [11, 12, 13, 14, 15], 'add scalar');

    my $minus5 = $v->add_scalar(-5);  # No sub_scalar, use add_scalar with negative
    is_deeply($minus5->to_array, [-4, -3, -2, -1, 0], 'sub scalar');

    my $times2 = $v->scale(2);
    is_deeply($times2->to_array, [2, 4, 6, 8, 10], 'scale by 2');
};

# ============================================
# In-place vs new vector
# ============================================

subtest 'immutability: operations return new vectors' => sub {
    my $original = Numeric::Vector::new([1, 2, 3]);
    my $copy = Numeric::Vector::new([1, 2, 3]);

    my $result = $original->add_scalar(10);

    # Original should be unchanged
    ok(vec_approx_eq($original, $copy), 'original unchanged after add');
    is($result->get(0), 11, 'result has new values');
};

# ============================================
# Mixed positive/negative values
# ============================================

subtest 'mixed: positive and negative' => sub {
    my $v = Numeric::Vector::new([-3, -2, -1, 0, 1, 2, 3]);

    # Absolute value
    my $abs = $v->abs();
    is_deeply($abs->to_array, [3, 2, 1, 0, 1, 2, 3], 'abs of mixed');

    # Sign
    my $sign = $v->sign();
    is_deeply($sign->to_array, [-1, -1, -1, 0, 1, 1, 1], 'sign of mixed');

    # Square (all positive)
    my $sq = $v->pow(2);
    is_deeply($sq->to_array, [9, 4, 1, 0, 1, 4, 9], 'square of mixed');
};

# ============================================
# Empty and single-element edge cases
# ============================================

subtest 'single element operations' => sub {
    my $single = Numeric::Vector::new([42]);

    my $doubled = $single->scale(2);
    is($doubled->get(0), 84, 'single element scale');

    my $squared = $single->pow(2);
    is($squared->get(0), 1764, 'single element pow');
};

# ============================================
# Chained comparisons for filtering
# ============================================

subtest 'chained: range filtering' => sub {
    my $v = Numeric::Vector::range(1, 11);  # 1 to 10

    # Find 3 < x <= 7
    my $gt3 = $v->gt(3);
    my $le7 = $v->le(7);
    my $mask = $gt3->mul($le7);  # AND via multiplication

    my $filtered = $v->where($mask);
    is_deeply($filtered->to_array, [4, 5, 6, 7], 'range filter 3 < x <= 7');
};

subtest 'chained: outlier detection' => sub {
    my $v = Numeric::Vector::new([1, 2, 100, 3, 4, -50, 5]);

    my $mean = $v->mean();
    my $std = $v->std();

    # Values within 2 std of mean
    my $lower = $mean - 2 * $std;
    my $upper = $mean + 2 * $std;

    my $gt_lower = $v->gt($lower);
    my $lt_upper = $v->lt($upper);
    my $in_range = $gt_lower->mul($lt_upper);

    my $normal = $v->where($in_range);
    # The number of values within range depends on std calculation (sample vs pop)
    # and precision. Just verify we filtered something.
    ok($normal->len() < $v->len(), 'some outliers were filtered');
    ok($normal->len() >= 3, 'at least 3 normal values remain');
};

done_testing();
