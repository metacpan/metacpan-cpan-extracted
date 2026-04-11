#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical qw(:all);
use_ok('Numeric::Vector');

# ============================================
# SIMD correctness tests across different sizes
# Tests various vector sizes to ensure correct
# handling of SIMD lanes and scalar tails
# ============================================

# SIMD lane sizes:
# - NEON: 2 doubles (128-bit)
# - SSE2: 2 doubles (128-bit)
# - AVX:  4 doubles (256-bit)
# - AVX2: 4 doubles (256-bit)

my @test_sizes = (
    1, 2, 3, 4,           # Small, around SIMD boundaries
    5, 6, 7, 8,           # One full AVX vector
    9, 15, 16, 17,        # Around 2x AVX
    31, 32, 33,           # Around 4x AVX
    63, 64, 65,           # Around 8x AVX
    100, 127, 128, 129,   # Larger
    255, 256, 257,        # Power of 2 boundaries
    1000, 1023, 1024, 1025,  # Large
);

my $tol = 1e-10;

sub is_float {
    my ($got, $expected, $name) = @_;
    if (abs($expected) < $tol) {
        ok(abs($got) < $tol, $name)
            or diag("got: $got, expected: ~0");
    } else {
        ok(abs($got - $expected) / abs($expected) < $tol, $name)
            or diag("got: $got, expected: $expected, diff: " . abs($got - $expected));
    }
}

# ============================================
# Sum correctness across sizes
# ============================================

subtest 'sum across sizes' => sub {
    for my $n (@test_sizes) {
        my $v = Numeric::Vector::fill($n, 1.0);
        is($v->sum, $n, "sum of $n ones = $n");
    }
};

subtest 'sum of range' => sub {
    for my $n (1, 10, 100, 1000) {
        my $v = Numeric::Vector::range(1, $n + 1);  # 1 to n
        my $expected = $n * ($n + 1) / 2;  # Gauss formula
        is_float($v->sum, $expected, "sum 1..$n = $expected");
    }
};

# ============================================
# Dot product correctness across sizes
# ============================================

subtest 'dot product across sizes' => sub {
    for my $n (@test_sizes) {
        my $a = Numeric::Vector::ones($n);
        my $b = Numeric::Vector::fill($n, 2.0);
        is_float($a->dot($b), 2.0 * $n, "dot: ones · 2s for n=$n");
    }
};

subtest 'dot product self' => sub {
    for my $n (1, 7, 8, 9, 31, 32, 33, 100) {
        my $v = Numeric::Vector::fill($n, 3.0);
        is_float($v->dot($v), 9.0 * $n, "dot: 3s · 3s for n=$n");
    }
};

# ============================================
# Element-wise operations across sizes
# ============================================

subtest 'add across sizes' => sub {
    for my $n (@test_sizes) {
        my $a = Numeric::Vector::fill($n, 1.0);
        my $b = Numeric::Vector::fill($n, 2.0);
        my $c = $a->add($b);

        is($c->len, $n, "add len for n=$n");
        is($c->get(0), 3.0, "add first for n=$n");
        is($c->get($n-1), 3.0, "add last for n=$n");
        is($c->sum, 3.0 * $n, "add sum for n=$n");
    }
};

subtest 'sub across sizes' => sub {
    for my $n (@test_sizes) {
        my $a = Numeric::Vector::fill($n, 5.0);
        my $b = Numeric::Vector::fill($n, 2.0);
        my $c = $a->sub($b);

        is($c->get(0), 3.0, "sub first for n=$n");
        is($c->get($n-1), 3.0, "sub last for n=$n");
    }
};

subtest 'mul across sizes' => sub {
    for my $n (@test_sizes) {
        my $a = Numeric::Vector::fill($n, 3.0);
        my $b = Numeric::Vector::fill($n, 4.0);
        my $c = $a->mul($b);

        is($c->get(0), 12.0, "mul first for n=$n");
        is($c->get($n-1), 12.0, "mul last for n=$n");
    }
};

subtest 'scale across sizes' => sub {
    for my $n (@test_sizes) {
        my $a = Numeric::Vector::ones($n);
        my $b = $a->scale(7.5);

        is($b->get(0), 7.5, "scale first for n=$n");
        is($b->get($n-1), 7.5, "scale last for n=$n");
        is_float($b->sum, 7.5 * $n, "scale sum for n=$n");
    }
};

# ============================================
# Reductions across sizes
# ============================================

subtest 'min/max across sizes' => sub {
    for my $n (@test_sizes) {
        my $v = Numeric::Vector::range(0, $n);  # 0, 1, ..., n-1

        is($v->min, 0, "min for n=$n");
        is($v->max, $n - 1, "max for n=$n");
        is($v->argmin, 0, "argmin for n=$n");
        is($v->argmax, $n - 1, "argmax for n=$n");
    }
};

subtest 'min/max with value in middle' => sub {
    for my $n (10, 32, 100, 256) {
        my $v = Numeric::Vector::zeros($n);
        my $mid = int($n / 2);

        $v->set($mid, 99);
        is($v->max, 99, "max in middle for n=$n");
        is($v->argmax, $mid, "argmax in middle for n=$n");

        $v->set($mid, -99);
        is($v->min, -99, "min in middle for n=$n");
        is($v->argmin, $mid, "argmin in middle for n=$n");
    }
};

subtest 'mean across sizes' => sub {
    for my $n (@test_sizes) {
        my $v = Numeric::Vector::fill($n, 42.0);
        is_float($v->mean, 42.0, "mean of constant for n=$n");
    }

    for my $n (2, 10, 100, 1000) {
        my $v = Numeric::Vector::range(1, $n + 1);  # 1 to n
        my $expected = ($n + 1) / 2.0;
        is_float($v->mean, $expected, "mean of 1..$n");
    }
};

# ============================================
# Norm and distance across sizes
# ============================================

subtest 'norm across sizes' => sub {
    for my $n (@test_sizes) {
        my $v = Numeric::Vector::ones($n);
        is_float($v->norm, sqrt($n), "norm of ones for n=$n");
    }
};

subtest 'distance across sizes' => sub {
    for my $n (@test_sizes) {
        my $a = Numeric::Vector::zeros($n);
        my $b = Numeric::Vector::ones($n);
        is_float($a->distance($b), sqrt($n), "distance zeros to ones for n=$n");
    }
};

# ============================================
# In-place operations across sizes
# ============================================

subtest 'add_inplace across sizes' => sub {
    for my $n (@test_sizes) {
        my $a = Numeric::Vector::fill($n, 1.0);
        my $b = Numeric::Vector::fill($n, 2.0);
        $a->add_inplace($b);

        is($a->get(0), 3.0, "add_inplace first for n=$n");
        is($a->get($n-1), 3.0, "add_inplace last for n=$n");
    }
};

subtest 'scale_inplace across sizes' => sub {
    for my $n (@test_sizes) {
        my $a = Numeric::Vector::fill($n, 2.0);
        $a->scale_inplace(3.0);

        is($a->get(0), 6.0, "scale_inplace first for n=$n");
        is($a->get($n-1), 6.0, "scale_inplace last for n=$n");
    }
};

# ============================================
# AXPY across sizes (y = a*x + y)
# ============================================

subtest 'axpy across sizes' => sub {
    for my $n (@test_sizes) {
        my $x = Numeric::Vector::ones($n);
        my $y = Numeric::Vector::fill($n, 10.0);

        $y->axpy(5.0, $x);  # y = 5*x + y = 5 + 10 = 15

        is($y->get(0), 15.0, "axpy first for n=$n");
        is($y->get($n-1), 15.0, "axpy last for n=$n");
        is_float($y->sum, 15.0 * $n, "axpy sum for n=$n");
    }
};

# ============================================
# FMA across sizes (c = a*b + c)
# ============================================

subtest 'fma_inplace across sizes' => sub {
    for my $n (@test_sizes) {
        my $a = Numeric::Vector::fill($n, 2.0);
        my $b = Numeric::Vector::fill($n, 3.0);
        my $c = Numeric::Vector::fill($n, 1.0);

        $c->fma_inplace($a, $b);  # c = 2*3 + 1 = 7

        is($c->get(0), 7.0, "fma first for n=$n");
        is($c->get($n-1), 7.0, "fma last for n=$n");
    }
};

# ============================================
# Variance/std across sizes
# ============================================

subtest 'variance of constant' => sub {
    for my $n (2, 10, 100, 1000) {
        my $v = Numeric::Vector::fill($n, 42.0);
        is_float($v->variance, 0.0, "variance of constant for n=$n");
        is_float($v->std, 0.0, "std of constant for n=$n");
    }
};

subtest 'variance of known distribution' => sub {
    # Variance of 1, 2, 3, ..., n is (n^2 - 1) / 12 for population
    # Sample variance (n-1 denominator) is n*(n+1)/12
    for my $n (10, 100, 1000) {
        my $v = Numeric::Vector::range(1, $n + 1);  # 1 to n
        my $expected_var = $n * ($n + 1) / 12.0;  # Sample variance
        is_float($v->variance, $expected_var, "variance of 1..$n");
    }
};

# ============================================
# Chained operations across sizes
# ============================================

subtest 'chained operations' => sub {
    for my $n (1, 7, 8, 9, 31, 32, 33, 100, 256) {
        my $a = Numeric::Vector::fill($n, 2.0);
        my $b = Numeric::Vector::fill($n, 3.0);

        # (a + b) * 2 - a = (2+3)*2 - 2 = 8
        my $result = $a->add($b)->scale(2.0)->sub($a);

        is($result->get(0), 8.0, "chained first for n=$n");
        is($result->get($n-1), 8.0, "chained last for n=$n");
    }
};

subtest 'normalize across sizes' => sub {
    for my $n (1, 7, 8, 9, 31, 32, 33, 100) {
        my $v = Numeric::Vector::fill($n, 3.0);
        my $unit = $v->normalize;

        is_float($unit->norm, 1.0, "normalized norm = 1 for n=$n");

        # All elements should be equal
        my $expected = 1.0 / sqrt($n);
        is_float($unit->get(0), $expected, "normalized element for n=$n");
    }
};

done_testing;
