#!/usr/bin/env perl
# Test Numeric::Vector numerical validation with known mathematical identities
# These tests validate correctness across precision levels
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
my $pi = 3.14159265358979323846;

# ============================================
# Mathematical identities
# ============================================

subtest 'identity: Pythagorean theorem' => sub {
    # a^2 + b^2 = c^2 for right triangles
    my @triangles = (
        [3, 4, 5],
        [5, 12, 13],
        [8, 15, 17],
        [7, 24, 25],
    );

    for my $t (@triangles) {
        my ($a, $b, $c) = @$t;
        my $v = Numeric::Vector::new([$a, $b]);
        my $hyp = $v->norm();
        ok(approx_eq($hyp, $c, $tol), "Pythagorean: $a^2 + $b^2 = $c^2");
    }
};

subtest 'identity: sum of arithmetic series' => sub {
    # Sum of 1 to n = n(n+1)/2
    for my $n (10, 100, 1000, 10000) {
        my $v = Numeric::Vector::range(1, $n + 1);
        my $sum = $v->sum();
        my $expected = $n * ($n + 1) / 2;
        ok(approx_eq($sum, $expected, $tol), "sum(1..$n) = $expected");
    }
};

subtest 'identity: sum of squares' => sub {
    # Sum of 1^2 to n^2 = n(n+1)(2n+1)/6
    for my $n (10, 100, 500) {
        my $v = Numeric::Vector::range(1, $n + 1)->pow(2);
        my $sum = $v->sum();
        my $expected = $n * ($n + 1) * (2 * $n + 1) / 6;
        within_tolerance($sum, $expected, "sum of squares 1..$n");
    }
};

subtest 'identity: geometric series' => sub {
    # Sum of r^0 + r^1 + ... + r^n = (1 - r^(n+1)) / (1 - r) for r != 1
    my $r = 0.5;
    my $n = 20;

    my @powers = map { $r ** $_ } 0..$n;
    my $v = Numeric::Vector::new(\@powers);
    my $sum = $v->sum();
    my $expected = (1 - $r ** ($n + 1)) / (1 - $r);

    within_tolerance($sum, $expected, "geometric series r=$r, n=$n");
};

# ============================================
# Trigonometric identities
# ============================================

subtest 'trig: sin^2 + cos^2 = 1' => sub {
    my @angles = map { $_ * $pi / 6 } 0..12;  # 0 to 2pi
    my $v = Numeric::Vector::new(\@angles);

    my $sin2 = $v->sin()->pow(2);
    my $cos2 = $v->cos()->pow(2);
    my $sum = $sin2->add($cos2);

    my $ones = Numeric::Vector::ones($v->len());
    ok(vec_approx_eq($sum, $ones), 'sin^2 + cos^2 = 1 for all angles');
};

subtest 'trig: sin(2x) = 2*sin(x)*cos(x)' => sub {
    my @angles = map { $_ * $pi / 8 } 1..7;  # Avoid 0 and pi
    my $x = Numeric::Vector::new(\@angles);

    # Left side: sin(2x)
    my $left = $x->scale(2)->sin();

    # Right side: 2*sin(x)*cos(x)
    my $right = $x->sin()->mul($x->cos())->scale(2);

    ok(vec_approx_eq($left, $right), 'sin(2x) = 2*sin(x)*cos(x)');
};

subtest 'trig: cos(2x) = cos^2(x) - sin^2(x)' => sub {
    my @angles = map { $_ * $pi / 8 } 1..7;
    my $x = Numeric::Vector::new(\@angles);

    # Left side: cos(2x)
    my $left = $x->scale(2)->cos();

    # Right side: cos^2(x) - sin^2(x)
    my $right = $x->cos()->pow(2)->sub($x->sin()->pow(2));

    ok(vec_approx_eq($left, $right), 'cos(2x) = cos^2(x) - sin^2(x)');
};

# ============================================
# Exponential and logarithm identities
# ============================================

subtest 'exp/log: exp(log(x)) = x' => sub {
    my $v = Numeric::Vector::new([0.1, 0.5, 1, 2, 5, 10, 100]);
    my $result = $v->log()->exp();
    ok(vec_approx_eq($result, $v), 'exp(log(x)) = x');
};

subtest 'exp/log: log(exp(x)) = x' => sub {
    my $v = Numeric::Vector::new([-2, -1, 0, 1, 2, 3]);
    my $result = $v->exp()->log();
    ok(vec_approx_eq($result, $v), 'log(exp(x)) = x');
};

subtest 'exp/log: log(a*b) = log(a) + log(b)' => sub {
    my $a = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $b = Numeric::Vector::new([5, 4, 3, 2, 1]);

    my $left = $a->mul($b)->log();
    my $right = $a->log()->add($b->log());

    ok(vec_approx_eq($left, $right), 'log(a*b) = log(a) + log(b)');
};

subtest 'exp/log: log(a^n) = n*log(a)' => sub {
    my $a = Numeric::Vector::new([2, 3, 4, 5]);
    my $n = 3;

    my $left = $a->pow($n)->log();
    my $right = $a->log()->scale($n);

    ok(vec_approx_eq($left, $right), 'log(a^n) = n*log(a)');
};

# ============================================
# Statistical properties
# ============================================

subtest 'stats: mean of uniform = (min+max)/2' => sub {
    my $v = Numeric::Vector::range(10, 21);  # 10 to 20
    my $mean = $v->mean();
    my $expected = (10 + 20) / 2;

    within_tolerance($mean, $expected, 'mean of uniform distribution');
};

subtest 'stats: z-score normalization' => sub {
    my $v = Numeric::Vector::new([10, 20, 30, 40, 50]);

    my $mean = $v->mean();
    my $std = $v->std();

    # z = (x - mean) / std
    my $z = $v->add_scalar(-$mean)->scale(1 / $std);

    # Z-scores should have mean ≈ 0 and std ≈ 1
    within_tolerance($z->mean(), 0, 'z-scores have mean 0');
    within_tolerance($z->std(), 1, 'z-scores have std 1', $tol * 10);
};

subtest 'stats: variance of scaled data' => sub {
    # Var(c*X) = c^2 * Var(X)
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $c = 3;

    my $var_original = $v->variance();
    my $var_scaled = $v->scale($c)->variance();

    within_tolerance($var_scaled, $c * $c * $var_original, 'Var(cX) = c^2*Var(X)');
};

subtest 'stats: variance of translated data' => sub {
    # Var(X + c) = Var(X)
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $c = 100;

    my $var_original = $v->variance();
    my $var_translated = $v->add_scalar($c)->variance();

    within_tolerance($var_translated, $var_original, 'Var(X+c) = Var(X)');
};

# ============================================
# Vector space properties
# ============================================

subtest 'vector: dot product is commutative' => sub {
    my $a = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $b = Numeric::Vector::new([5, 4, 3, 2, 1]);

    my $ab = $a->dot($b);
    my $ba = $b->dot($a);

    ok(approx_eq($ab, $ba, $tol), 'a.b = b.a');
};

subtest 'vector: |a|^2 = a.a' => sub {
    my $a = Numeric::Vector::new([3, 4, 5, 6]);

    my $norm_sq = $a->norm() ** 2;
    my $dot_aa = $a->dot($a);

    ok(approx_eq($norm_sq, $dot_aa, $tol), '|a|^2 = a.a');
};

subtest 'vector: Cauchy-Schwarz inequality' => sub {
    # |a.b| <= |a| * |b|
    my $a = Numeric::Vector::new([1, 2, 3]);
    my $b = Numeric::Vector::new([4, 5, 6]);

    my $dot = abs($a->dot($b));
    my $product = $a->norm() * $b->norm();

    ok($dot <= $product + $tol, 'Cauchy-Schwarz: |a.b| <= |a||b|');
};

subtest 'vector: unit vector has norm 1' => sub {
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $unit = $v->normalize();

    within_tolerance($unit->norm(), 1.0, 'normalized vector has unit length');
};

# ============================================
# Numerical stability checks
# ============================================

subtest 'stability: orthogonality after normalization' => sub {
    # Create orthogonal vectors
    my $a = Numeric::Vector::new([1, 0, 0]);
    my $b = Numeric::Vector::new([0, 1, 0]);

    # Their dot product should be 0
    my $dot = $a->dot($b);
    ok(approx_eq($dot, 0, $tol), 'orthogonal vectors: a.b = 0');
};

subtest 'stability: triangle inequality' => sub {
    # |a + b| <= |a| + |b|
    my $a = Numeric::Vector::new([1, 2, 3]);
    my $b = Numeric::Vector::new([-1, 1, 2]);

    my $sum_norm = $a->add($b)->norm();
    my $norm_sum = $a->norm() + $b->norm();

    ok($sum_norm <= $norm_sum + $tol, 'triangle inequality: |a+b| <= |a|+|b|');
};

subtest 'stability: cumsum then diff recovers original' => sub {
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);

    # Prepend 0, cumsum, then diff should give original
    my $csum = $v->cumsum();
    my $zeros = Numeric::Vector::zeros(1);
    my $with_zero = $zeros->concat($csum);
    my $recovered = $with_zero->diff();

    ok(vec_approx_eq($v, $recovered), 'diff(cumsum(v)) = v (with prepended 0)');
};

# ============================================
# Edge case validation
# ============================================

subtest 'edge: operations on length-1 vectors' => sub {
    my $single = Numeric::Vector::new([42]);

    is($single->sum(), 42, 'sum of single');
    is($single->mean(), 42, 'mean of single');
    is($single->min(), 42, 'min of single');
    is($single->max(), 42, 'max of single');
    is($single->median(), 42, 'median of single');
    is($single->product(), 42, 'product of single');
    is($single->norm(), 42, 'norm of single');
};

subtest 'edge: all zeros vector' => sub {
    my $zeros = Numeric::Vector::zeros(10);

    is($zeros->sum(), 0, 'sum of zeros');
    is($zeros->mean(), 0, 'mean of zeros');
    is($zeros->variance(), 0, 'variance of zeros');
    is($zeros->std(), 0, 'std of zeros');
    is($zeros->product(), 0, 'product of zeros');
};

subtest 'edge: all ones vector' => sub {
    my $ones = Numeric::Vector::ones(10);

    is($ones->sum(), 10, 'sum of ones');
    is($ones->mean(), 1, 'mean of ones');
    is($ones->variance(), 0, 'variance of ones');
    is($ones->std(), 0, 'std of ones');
    is($ones->product(), 1, 'product of ones');
};

# ============================================
# Cross-validation with analytical solutions
# ============================================

subtest 'analytical: exponential decay' => sub {
    # e^(-x) for x = 0, 1, 2, 3, 4
    my $x = Numeric::Vector::range(0, 5);
    my $decay = $x->scale(-1)->exp();

    my @expected = map { exp(-$_) } 0..4;
    my @got = @{$decay->to_array};

    for my $i (0..4) {
        ok(approx_eq($got[$i], $expected[$i], $tol), "exp(-$i) correct");
    }
};

subtest 'analytical: polynomial evaluation' => sub {
    # p(x) = x^2 - 2x + 1 = (x-1)^2
    my $x = Numeric::Vector::new([0, 1, 2, 3, 4]);

    my $x2 = $x->pow(2);
    my $x1 = $x->scale(-2);
    my $p = $x2->add($x1)->add_scalar(1);

    # Expected: (0-1)^2=1, (1-1)^2=0, (2-1)^2=1, (3-1)^2=4, (4-1)^2=9
    is_deeply($p->to_array, [1, 0, 1, 4, 9], 'polynomial (x-1)^2 evaluated correctly');
};

subtest 'analytical: derivative approximation' => sub {
    # For f(x) = x^2, f'(x) = 2x
    # Using forward difference: f'(x) ≈ (f(x+h) - f(x)) / h
    my $x = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $h = 0.0001;

    my $fx = $x->pow(2);
    my $fxh = $x->add_scalar($h)->pow(2);
    my $deriv = $fxh->sub($fx)->scale(1 / $h);

    # Expected: 2x = [2, 4, 6, 8, 10]
    # Note: forward difference has error O(h), so use looser tolerance
    my $expected = $x->scale(2);
    my $diff = $deriv->sub($expected)->abs();
    my $max_error = $diff->max();
    ok($max_error < $h * 2, "numerical derivative error < $h*2 (got $max_error)");
};

done_testing();
