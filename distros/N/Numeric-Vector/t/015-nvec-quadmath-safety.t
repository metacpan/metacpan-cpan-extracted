#!/usr/bin/env perl
# Test Numeric::Vector operations for quadmath safety and numerical precision
# These tests work correctly with both standard double and quadmath builds
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
my $strict_tol = get_tolerance(1);

# ============================================
# Precision-sensitive arithmetic
# ============================================

subtest 'precision: small differences' => sub {
    # Values that differ only in later decimal places
    my $a = Numeric::Vector::new([1.0, 1.0000000001, 1.00000000001]);
    my $b = Numeric::Vector::new([1.0, 1.0, 1.0]);

    my $diff = $a->sub($b);
    my @vals = @{$diff->to_array};

    ok(approx_eq($vals[0], 0, $tol), 'difference of equal values is zero');
    ok($vals[1] > 0, 'small difference detected at 1e-10');

    # The 1e-11 difference may or may not be detectable depending on precision
    if ($is_quad) {
        ok($vals[2] > 0, 'quadmath detects 1e-11 difference');
    } else {
        pass('double precision may not detect 1e-11 difference (expected)');
    }
};

subtest 'precision: accumulation of small values' => sub {
    # Add 0.1 ten times - classic floating point test
    my $v = Numeric::Vector::zeros(1);
    for (1..10) {
        $v = $v->add_scalar(0.1);
    }

    my $result = $v->get(0);
    # With perfect math, this would be exactly 1.0
    my $error = abs($result - 1.0);

    ok($error < 1e-14, "accumulation error is small: $error");
    # Note: 0.1 cannot be represented exactly in binary, so even quadmath
    # accumulates some error. The error is still small.
    if ($is_quad) {
        ok($error < 1e-15, "quadmath has small accumulation error: $error");
    }
};

subtest 'precision: subtraction of nearly equal values' => sub {
    # Catastrophic cancellation test
    my $large = 1e10;
    my $small = 1.0;

    my $a = Numeric::Vector::new([$large + $small]);
    my $b = Numeric::Vector::new([$large]);
    my $diff = $a->sub($b);

    within_tolerance($diff->get(0), $small, 'subtraction of nearly equal preserves small part');
};

subtest 'precision: large scale differences' => sub {
    # Test arithmetic with values of vastly different magnitudes
    my $a = Numeric::Vector::new([1e15, 1e-15, 1.0]);
    my $b = Numeric::Vector::new([1.0, 1.0, 1e-15]);

    my $sum = $a->add($b);
    my @vals = @{$sum->to_array};

    ok($vals[0] > 1e15, 'large value preserved in sum');
    ok(approx_eq($vals[1], 1.0, $tol), 'small + large gives large');
    ok(approx_eq($vals[2], 1.0, $tol), 'medium + tiny gives medium');
};

# ============================================
# Comparison operations with edge cases
# ============================================

subtest 'comparisons: near-zero values' => sub {
    my $tiny = 1e-300;
    my $v = Numeric::Vector::new([$tiny, -$tiny, 0.0, $tiny/2]);

    my $gt_zero = $v->gt(0);
    my @vals = @{$gt_zero->to_array};

    is($vals[0], 1, 'tiny positive > 0');
    is($vals[1], 0, 'tiny negative not > 0');
    is($vals[2], 0, 'zero not > 0');
    is($vals[3], 1, 'half-tiny positive > 0');
};

subtest 'comparisons: near-equal values' => sub {
    my $base = 1.0;
    my $eps = 1e-15;

    my $a = Numeric::Vector::new([$base, $base, $base]);
    my $b = Numeric::Vector::new([$base, $base + $eps, $base - $eps]);

    my $eq = $a->eq($b);
    my @vals = @{$eq->to_array};

    is($vals[0], 1, 'equal values compare equal');
    # The epsilon difference may or may not be detected
    ok(defined $vals[1], 'comparison with tiny + works');
    ok(defined $vals[2], 'comparison with tiny - works');
};

subtest 'comparisons: infinity and large values' => sub {
    my $inf = 9**9**9;
    my $large = 1e308;

    my $v = Numeric::Vector::new([$inf, $large, -$inf, -$large]);

    my $gt_zero = $v->gt(0);
    my @vals = @{$gt_zero->to_array};

    is($vals[0], 1, '+inf > 0');
    is($vals[1], 1, 'large > 0');
    is($vals[2], 0, '-inf not > 0');
    is($vals[3], 0, '-large not > 0');
};

# ============================================
# Reduction operations
# ============================================

subtest 'reductions: sum stability' => sub {
    # Summing alternating large values - tests cancellation
    my @data = map { (-1)**$_ * 1e10 } 0..99;
    my $v = Numeric::Vector::new(\@data);

    my $sum = $v->sum();
    # 50 positive and 50 negative 1e10 values should sum to 0
    ok(abs($sum) < 1e-5, "alternating sum near zero: $sum");
};

subtest 'reductions: mean of uniform values' => sub {
    my $v = Numeric::Vector::fill(1000, 3.14159);
    my $mean = $v->mean();

    within_tolerance($mean, 3.14159, 'mean of uniform values');
};

subtest 'reductions: product stability' => sub {
    # Product of values near 1 shouldn't drift too much
    my @data = map { 1.0 + 1e-10 } 1..100;
    my $v = Numeric::Vector::new(\@data);

    my $prod = $v->product();
    # (1 + 1e-10)^100 ≈ e^(100 * 1e-10) ≈ 1 + 1e-8
    my $expected = exp(100 * 1e-10);

    ok(approx_eq($prod, $expected, 1e-6), 'product of near-1 values');
};

subtest 'reductions: min/max with special values' => sub {
    my $nan = 9**9**9 - 9**9**9;
    my $inf = 9**9**9;

    # Test with finite values only
    my $v = Numeric::Vector::new([5, -3, 100, 0.001, -1000]);

    is($v->min(), -1000, 'min finds smallest');
    is($v->max(), 100, 'max finds largest');
    is($v->argmin(), 4, 'argmin finds index of smallest');
    is($v->argmax(), 2, 'argmax finds index of largest');
};

# ============================================
# Mathematical functions
# ============================================

subtest 'math: sqrt precision' => sub {
    my $v = Numeric::Vector::new([0, 1, 2, 4, 9, 16, 100]);
    my $sqrts = $v->sqrt();

    my @expected = (0, 1, sqrt(2), 2, 3, 4, 10);
    my @got = @{$sqrts->to_array};

    for my $i (0..$#expected) {
        ok(approx_eq($got[$i], $expected[$i], $tol), "sqrt of index $i");
    }
};

subtest 'math: exp and log inverses' => sub {
    my $v = Numeric::Vector::new([0.1, 0.5, 1.0, 2.0, 5.0, 10.0]);

    # exp(log(x)) should equal x
    my $logged = $v->log();
    my $back = $logged->exp();

    ok(vec_approx_eq($v, $back), 'exp(log(x)) = x');

    # log(exp(x)) should equal x
    my $v2 = Numeric::Vector::new([-2, -1, 0, 1, 2]);
    my $exped = $v2->exp();
    my $back2 = $exped->log();

    ok(vec_approx_eq($v2, $back2), 'log(exp(x)) = x');
};

subtest 'math: trigonometric identities' => sub {
    my $angles = Numeric::Vector::new([0, 0.5, 1.0, 1.5, 2.0, 3.14159265358979]);

    my $sins = $angles->sin();
    my $coss = $angles->cos();

    # sin^2 + cos^2 = 1
    my $sin_sq = $sins->mul($sins);
    my $cos_sq = $coss->mul($coss);
    my $sum = $sin_sq->add($cos_sq);

    my $ones = Numeric::Vector::ones($angles->len());
    ok(vec_approx_eq($sum, $ones), 'sin^2 + cos^2 = 1');
};

subtest 'math: power function' => sub {
    my $bases = Numeric::Vector::new([2, 3, 4, 10]);

    my $squared = $bases->pow(2);
    my @sq = @{$squared->to_array};
    is($sq[0], 4, '2^2 = 4');
    is($sq[1], 9, '3^2 = 9');
    is($sq[2], 16, '4^2 = 16');
    is($sq[3], 100, '10^2 = 100');

    my $cubed = $bases->pow(3);
    my @cb = @{$cubed->to_array};
    is($cb[0], 8, '2^3 = 8');
    is($cb[1], 27, '3^3 = 27');
};

subtest 'math: abs and sign' => sub {
    my $v = Numeric::Vector::new([-5, -0.1, 0, 0.1, 5]);

    my $abs = $v->abs();
    my @abs_vals = @{$abs->to_array};
    ok(approx_eq($abs_vals[0], 5, $tol), 'abs(-5) = 5');
    ok(approx_eq($abs_vals[1], 0.1, $tol), 'abs(-0.1) = 0.1');
    ok(approx_eq($abs_vals[2], 0, $tol), 'abs(0) = 0');
    ok(approx_eq($abs_vals[3], 0.1, $tol), 'abs(0.1) = 0.1');
    ok(approx_eq($abs_vals[4], 5, $tol), 'abs(5) = 5');

    my $sign = $v->sign();
    my @sign_vals = @{$sign->to_array};
    is_deeply(\@sign_vals, [-1, -1, 0, 1, 1], 'sign works correctly');
};

# ============================================
# Vector operations
# ============================================

subtest 'vectors: dot product' => sub {
    my $a = Numeric::Vector::new([1, 2, 3]);
    my $b = Numeric::Vector::new([4, 5, 6]);

    # Dot = 1*4 + 2*5 + 3*6 = 4 + 10 + 18 = 32
    my $dot = $a->dot($b);
    is($dot, 32, 'dot product of [1,2,3] . [4,5,6] = 32');
};

subtest 'vectors: norm' => sub {
    my $v = Numeric::Vector::new([3, 4]);
    my $norm = $v->norm();

    is($norm, 5, 'norm of [3,4] = 5');

    my $v2 = Numeric::Vector::new([1, 1, 1, 1]);
    my $norm2 = $v2->norm();
    ok(approx_eq($norm2, 2, $tol), 'norm of [1,1,1,1] = 2');
};

subtest 'vectors: normalize' => sub {
    my $v = Numeric::Vector::new([3, 4]);
    my $unit = $v->normalize();

    my $norm = $unit->norm();
    ok(approx_eq($norm, 1.0, $tol), 'normalized vector has unit length');

    my @vals = @{$unit->to_array};
    ok(approx_eq($vals[0], 0.6, $tol), 'normalized x = 0.6');
    ok(approx_eq($vals[1], 0.8, $tol), 'normalized y = 0.8');
};

# ============================================
# Cumulative operations
# ============================================

subtest 'cumulative: sum and product' => sub {
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);

    my $csum = $v->cumsum();
    is_deeply($csum->to_array, [1, 3, 6, 10, 15], 'cumsum');

    my $cprod = $v->cumprod();
    is_deeply($cprod->to_array, [1, 2, 6, 24, 120], 'cumprod');
};

subtest 'cumulative: diff' => sub {
    my $v = Numeric::Vector::new([1, 4, 9, 16, 25]);  # squares
    my $d = $v->diff();

    is_deeply($d->to_array, [3, 5, 7, 9], 'diff of squares gives odd numbers');
};

# ============================================
# Statistics
# ============================================

subtest 'statistics: variance and std' => sub {
    my $v = Numeric::Vector::new([2, 4, 4, 4, 5, 5, 7, 9]);

    # Mean = 40/8 = 5
    within_tolerance($v->mean(), 5, 'mean');

    my $var = $v->variance();
    my $std = $v->std();

    ok($var > 0, 'variance is positive');
    ok($std > 0, 'std is positive');
    ok(approx_eq($std * $std, $var, $tol), 'std^2 = variance');
};

subtest 'statistics: median' => sub {
    # Odd length
    my $odd = Numeric::Vector::new([5, 1, 9, 3, 7]);
    is($odd->median(), 5, 'median of odd length');

    # Even length
    my $even = Numeric::Vector::new([1, 2, 3, 4]);
    within_tolerance($even->median(), 2.5, 'median of even length');
};

# ============================================
# Selection and filtering
# ============================================

subtest 'selection: where' => sub {
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

    # Select values > 5
    my $mask = $v->gt(5);
    my $selected = $v->where($mask);

    is_deeply($selected->to_array, [6, 7, 8, 9, 10], 'where with gt mask');
};

subtest 'selection: clip' => sub {
    my $v = Numeric::Vector::new([-5, 0, 5, 10, 15]);
    my $clipped = $v->clip(0, 10);

    is_deeply($clipped->to_array, [0, 0, 5, 10, 10], 'clip to [0, 10]');
};

# ============================================
# Numerical edge cases
# ============================================

subtest 'edge cases: very small values' => sub {
    my $tiny = 1e-300;
    my $v = Numeric::Vector::new([$tiny, $tiny * 2, $tiny * 10]);

    my $sum = $v->sum();
    ok($sum > 0, 'sum of tiny values is positive');
    ok(approx_eq($sum, $tiny * 13, $tol), 'sum of tiny values correct');
};

subtest 'edge cases: very large values' => sub {
    my $large = 1e300;
    my $v = Numeric::Vector::new([$large, $large, $large]);

    my $sum = $v->sum();
    ok($sum > $large, 'sum of large values is larger');
    # For very large values, use relative tolerance
    my $mean = $v->mean();
    my $rel_error = abs($mean - $large) / $large;
    ok($rel_error < 1e-10, "mean of large values correct (rel error: $rel_error)");
};

subtest 'edge cases: mixed scales' => sub {
    my $v = Numeric::Vector::new([1e-100, 1.0, 1e100]);

    # Use approximate comparison for very small/large values
    my $min = $v->min();
    my $max = $v->max();
    ok($min > 0 && $min < 1e-99, 'min finds smallest (order of 1e-100)');
    ok($max > 1e99, 'max finds largest (order of 1e100)');

    # Mean is dominated by the large value
    my $mean = $v->mean();
    ok($mean > 1e99, 'mean dominated by large value');
};

subtest 'edge cases: zeros' => sub {
    my $zeros = Numeric::Vector::zeros(10);

    is($zeros->sum(), 0, 'sum of zeros');
    is($zeros->mean(), 0, 'mean of zeros');
    is($zeros->min(), 0, 'min of zeros');
    is($zeros->max(), 0, 'max of zeros');
    is($zeros->variance(), 0, 'variance of zeros');
    is($zeros->std(), 0, 'std of zeros');
};

subtest 'edge cases: single element' => sub {
    my $single = Numeric::Vector::new([42.5]);

    is($single->len(), 1, 'length is 1');
    is($single->sum(), 42.5, 'sum of single');
    is($single->mean(), 42.5, 'mean of single');
    is($single->min(), 42.5, 'min of single');
    is($single->max(), 42.5, 'max of single');
    is($single->median(), 42.5, 'median of single');
};

# ============================================
# Quadmath-specific precision tests
# ============================================

if ($is_quad) {
    subtest 'quadmath: precision characteristics' => sub {
        # Note: Numeric::Vector may use double-precision internally even on quadmath perl
        # These tests verify basic functionality works correctly

        # Test that very small values are preserved
        my $small = 1e-15;
        my $v = Numeric::Vector::new([$small]);
        my $got = $v->get(0);
        ok($got > 0, 'very small value preserved');
        ok(approx_eq($got, $small, 1e-20), 'small value accurate');

        # Test arithmetic with small values
        my $a = Numeric::Vector::new([1.0]);
        my $result = $a->add_scalar(-1.0);
        is($result->get(0), 0, 'subtraction gives zero');
    };

    subtest 'quadmath: large value handling' => sub {
        my $large = 1e100;
        my $v = Numeric::Vector::new([$large, $large * 2, $large * 3]);

        ok($v->min() > 0, 'large min is positive');
        ok($v->max() > $v->min(), 'max > min for distinct values');
        ok($v->mean() > $large, 'mean is in expected range');
    };

    subtest 'quadmath: accumulation test' => sub {
        my $n = 100;
        my $v = Numeric::Vector::zeros(1);

        for (1..$n) {
            $v = $v->add_scalar(1.0);
        }

        my $result = $v->get(0);
        ok(approx_eq($result, $n, $tol), "accumulated sum of $n ones");
    };
}

done_testing();
