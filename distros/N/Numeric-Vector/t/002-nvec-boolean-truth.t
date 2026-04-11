#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical qw(:all);
use_ok('Numeric::Vector');

# ============================================
# Boolean/truth value testing
# Testing conditions that could be affected by
# floating point precision (quadmath-aware)
# ============================================

# Tolerance for floating point comparisons
# Use larger tolerance to be quadmath-safe
my $tol = 1e-10;

sub is_float {
    my ($got, $expected, $name) = @_;
    if (abs($expected) < $tol) {
        ok(abs($got) < $tol, $name)
            or diag("got: $got, expected: ~0");
    } else {
        ok(abs($got - $expected) / abs($expected) < $tol, $name)
            or diag("got: $got, expected: $expected");
    }
}

# ============================================
# Boolean context tests
# ============================================

subtest 'boolean context - empty vs non-empty' => sub {
    my $empty = Numeric::Vector::new([]);
    my $single = Numeric::Vector::new([0]);  # Single zero
    my $zeros = Numeric::Vector::zeros(5);
    my $ones = Numeric::Vector::ones(5);

    # Empty is false
    ok(!$empty, 'empty vector is false in boolean context');

    # Non-empty vectors are true (even if all zeros)
    ok($single, 'single-element vector is true');
    ok($zeros, 'zeros vector is true (has elements)');
    ok($ones, 'ones vector is true');
};

# ============================================
# any() - returns true if ANY element is nonzero
# ============================================

subtest 'any() truth conditions' => sub {
    # All zeros - should be false
    ok(!Numeric::Vector::zeros(10)->any, 'any: all zeros is false');
    ok(!Numeric::Vector::new([])->any, 'any: empty is false');

    # Single nonzero
    ok(Numeric::Vector::new([0, 0, 1, 0])->any, 'any: single 1 is true');
    ok(Numeric::Vector::new([0, 0, -1, 0])->any, 'any: single -1 is true');

    # Very small nonzero (quadmath-safe check)
    ok(Numeric::Vector::new([0, 0, 1e-308, 0])->any, 'any: very small positive is true');
    ok(Numeric::Vector::new([0, 0, -1e-308, 0])->any, 'any: very small negative is true');

    # All nonzero
    ok(Numeric::Vector::ones(10)->any, 'any: all ones is true');
    ok(Numeric::Vector::fill(10, -1)->any, 'any: all -1 is true');
};

# ============================================
# all() - returns true if ALL elements are nonzero
# ============================================

subtest 'all() truth conditions' => sub {
    # Empty - vacuous truth
    ok(Numeric::Vector::new([])->all, 'all: empty is true (vacuous)');

    # All zeros
    ok(!Numeric::Vector::zeros(10)->all, 'all: all zeros is false');

    # Single zero among nonzeros
    ok(!Numeric::Vector::new([1, 2, 0, 4])->all, 'all: one zero is false');
    ok(!Numeric::Vector::new([1, 2, 3, 0])->all, 'all: trailing zero is false');
    ok(!Numeric::Vector::new([0, 2, 3, 4])->all, 'all: leading zero is false');

    # All nonzero
    ok(Numeric::Vector::ones(10)->all, 'all: all ones is true');
    ok(Numeric::Vector::fill(10, -1)->all, 'all: all -1 is true');
    ok(Numeric::Vector::new([0.1, 0.01, 0.001])->all, 'all: small nonzeros is true');
};

# ============================================
# count() - count of nonzero elements
# ============================================

subtest 'count() nonzero elements' => sub {
    is(Numeric::Vector::zeros(10)->count, 0, 'count: all zeros');
    is(Numeric::Vector::ones(10)->count, 10, 'count: all ones');
    is(Numeric::Vector::new([1, 0, 1, 0, 1])->count, 3, 'count: mixed');
    is(Numeric::Vector::new([])->count, 0, 'count: empty');

    # Negative values count as nonzero
    is(Numeric::Vector::new([-1, 0, -1, 0])->count, 2, 'count: negatives');

    # Very small values count as nonzero
    is(Numeric::Vector::new([1e-300, 0, 1e-300])->count, 2, 'count: tiny values');
};

# ============================================
# Equality operators (== and !=)
# ============================================

subtest 'equality operator ==' => sub {
    my $a = Numeric::Vector::new([1, 2, 3]);
    my $b = Numeric::Vector::new([1, 2, 3]);
    my $c = Numeric::Vector::new([1, 2, 4]);
    my $d = Numeric::Vector::new([1, 2]);

    # Same values
    ok($a == $b, '== same values');

    # Different values
    ok(!($a == $c), '== different values');

    # Different lengths
    ok(!($a == $d), '== different lengths');

    # Self equality
    ok($a == $a, '== self');

    # Empty vectors
    my $e1 = Numeric::Vector::new([]);
    my $e2 = Numeric::Vector::new([]);
    ok($e1 == $e2, '== empty vectors');
};

subtest 'inequality operator !=' => sub {
    my $a = Numeric::Vector::new([1, 2, 3]);
    my $b = Numeric::Vector::new([1, 2, 3]);
    my $c = Numeric::Vector::new([1, 2, 4]);

    ok(!($a != $b), '!= same values is false');
    ok($a != $c, '!= different values is true');
    ok(!($a != $a), '!= self is false');
};

# ============================================
# Floating point comparison (quadmath-aware)
# ============================================

subtest 'floating point truth - precision' => sub {
    # Values that should be equal but might differ in low bits
    my $a = Numeric::Vector::new([1.0/3.0, 2.0/3.0]);
    my $b = Numeric::Vector::new([0.333333333333333, 0.666666666666666]);

    # These may not be exactly equal due to precision
    my $diff = $a->sub($b)->abs;
    ok($diff->max < 1e-10, 'float precision: diff is small');

    # Sum of 0.1 ten times
    my $sum = Numeric::Vector::fill(10, 0.1)->sum;
    is_float($sum, 1.0, 'sum of 0.1 x 10 ≈ 1.0');

    # Associativity check (may differ with quadmath)
    my $v1 = Numeric::Vector::new([1e-15, 1, -1]);
    my $v2 = Numeric::Vector::new([1, -1, 1e-15]);
    is_float($v1->sum, $v2->sum, 'sum associativity');
};

subtest 'near-zero comparisons' => sub {
    my $tiny = 1e-15;
    my $v = Numeric::Vector::new([$tiny, -$tiny, 0]);

    ok($v->any, 'tiny nonzero values: any is true');
    ok(!$v->all, 'with zero: all is false');
    is($v->count, 2, 'count of tiny values');

    # eq comparison near zero
    my $zeros = Numeric::Vector::zeros(3);
    my $eq = $v->eq($zeros);
    is($eq->get(2), 1, 'eq: zero equals zero');
    is($eq->get(0), 0, 'eq: tiny != zero');
};

# ============================================
# Comparison functions element-wise truth
# ============================================

subtest 'element-wise eq truth' => sub {
    my $a = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $b = Numeric::Vector::new([1, 0, 3, 0, 5]);

    my $eq = $a->eq($b);
    is_deeply($eq->to_array, [1, 0, 1, 0, 1], 'eq element-wise');
    is($eq->count, 3, 'eq count matches');
    ok($eq->any, 'eq has some matches');
    ok(!$eq->all, 'eq not all match');
};

subtest 'element-wise comparisons' => sub {
    my $a = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $thresh = Numeric::Vector::fill(5, 3);

    my $lt = $a->lt($thresh);
    is_deeply($lt->to_array, [1, 1, 0, 0, 0], 'lt threshold');
    is($lt->count, 2, 'lt count');

    my $le = $a->le($thresh);
    is_deeply($le->to_array, [1, 1, 1, 0, 0], 'le threshold');
    is($le->count, 3, 'le count');

    my $gt = $a->gt($thresh);
    is_deeply($gt->to_array, [0, 0, 0, 1, 1], 'gt threshold');
    is($gt->count, 2, 'gt count');

    my $ge = $a->ge($thresh);
    is_deeply($ge->to_array, [0, 0, 1, 1, 1], 'ge threshold');
    is($ge->count, 3, 'ge count');
};

# ============================================
# Conditional selection with where()
# ============================================

subtest 'where with boolean masks' => sub {
    my $data = Numeric::Vector::range(0, 10);  # 0-9

    # Select even numbers
    my $is_even = Numeric::Vector::new([1, 0, 1, 0, 1, 0, 1, 0, 1, 0]);
    my $evens = $data->where($is_even);
    is_deeply($evens->to_array, [0, 2, 4, 6, 8], 'where: even numbers');

    # Select values > 5
    my $thresh = Numeric::Vector::fill(10, 5);
    my $gt5 = $data->gt($thresh);
    my $big = $data->where($gt5);
    is_deeply($big->to_array, [6, 7, 8, 9], 'where: > 5');

    # Chained: values > 3 AND < 7
    my $gt3 = $data->gt(Numeric::Vector::fill(10, 3));
    my $lt7 = $data->lt(Numeric::Vector::fill(10, 7));
    my $mask = $gt3->mul($lt7);  # AND via multiplication
    my $mid = $data->where($mask);
    is_deeply($mid->to_array, [4, 5, 6], 'where: 3 < x < 7');
};

# ============================================
# Sign function truth
# ============================================

subtest 'sign function' => sub {
    my $v = Numeric::Vector::new([-5, -0.001, 0, 0.001, 5]);
    my $s = $v->sign;

    is_deeply($s->to_array, [-1, -1, 0, 1, 1], 'sign values');

    # Sign of zeros
    my $zeros = Numeric::Vector::zeros(3);
    is_deeply($zeros->sign->to_array, [0, 0, 0], 'sign of zeros');

    # Sign of ones
    my $ones = Numeric::Vector::ones(3);
    is_deeply($ones->sign->to_array, [1, 1, 1], 'sign of ones');
};

# ============================================
# Special value checks
# ============================================

subtest 'isfinite, isnan, isinf' => sub {
    use POSIX qw(HUGE_VAL);
    my $inf = HUGE_VAL;
    my $nan = $inf - $inf;  # NaN

    my $v = Numeric::Vector::new([1.0, $nan, $inf, -$inf, 0]);

    my $finite = $v->isfinite;
    is($finite->get(0), 1, 'isfinite: 1.0');
    is($finite->get(1), 0, 'isfinite: NaN');
    is($finite->get(2), 0, 'isfinite: Inf');
    is($finite->get(3), 0, 'isfinite: -Inf');
    is($finite->get(4), 1, 'isfinite: 0');

    my $is_nan = $v->isnan;
    is($is_nan->get(0), 0, 'isnan: 1.0');
    is($is_nan->get(1), 1, 'isnan: NaN');
    is($is_nan->get(2), 0, 'isnan: Inf');

    my $is_inf = $v->isinf;
    is($is_inf->get(0), 0, 'isinf: 1.0');
    is($is_inf->get(1), 0, 'isinf: NaN');
    is($is_inf->get(2), 1, 'isinf: Inf');
    is($is_inf->get(3), 1, 'isinf: -Inf');
};

# ============================================
# Chained boolean operations
# ============================================

subtest 'chained truth operations' => sub {
    my $data = Numeric::Vector::new([1, 0, 3, 0, 5, 0, 7, 0, 9, 0]);

    # Filter nonzero, then check if any > 5
    my $nonzero_mask = $data->gt(Numeric::Vector::zeros(10));
    my $nonzero = $data->where($nonzero_mask);
    ok($nonzero->gt(Numeric::Vector::fill($nonzero->len, 5))->any, 'chained: some > 5');

    # Count how many satisfy complex condition
    my $gt3 = $data->gt(Numeric::Vector::fill(10, 3));
    my $lt8 = $data->lt(Numeric::Vector::fill(10, 8));
    my $both = $gt3->mul($lt8);
    is($both->count, 2, 'chained: count 3 < x < 8');
};

done_testing;
