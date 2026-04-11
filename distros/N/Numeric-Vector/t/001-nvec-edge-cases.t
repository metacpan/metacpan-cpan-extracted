#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical qw(:all);
use_ok('Numeric::Vector');

my $eps = 1e-10;

sub approx_eq {
    my ($a, $b, $msg) = @_;
    ok(abs($a - $b) < $eps, $msg // "approx equal: $a ≈ $b");
}

# ============================================
# Empty vector edge cases
# ============================================

subtest 'empty vector operations' => sub {
    my $empty = Numeric::Vector::new([]);
    is($empty->len, 0, 'empty len');
    is($empty->sum, 0, 'empty sum');
    is($empty->product, 1, 'empty product');
    is($empty->mean, 0, 'empty mean');
    is($empty->variance, 0, 'empty variance');
    is($empty->std, 0, 'empty std');
    ok(!$empty->any, 'empty any is false');
    ok($empty->all, 'empty all is true (vacuous truth)');
    is($empty->count, 0, 'empty count');

    my $arr = $empty->to_array;
    is_deeply($arr, [], 'empty to_array');

    my $copy = $empty->copy;
    is($copy->len, 0, 'copy of empty');
};

subtest 'single element vector' => sub {
    my $single = Numeric::Vector::new([42]);
    is($single->len, 1, 'single len');
    is($single->sum, 42, 'single sum');
    is($single->product, 42, 'single product');
    is($single->mean, 42, 'single mean');
    is($single->min, 42, 'single min');
    is($single->max, 42, 'single max');
    is($single->argmin, 0, 'single argmin');
    is($single->argmax, 0, 'single argmax');
    is($single->variance, 0, 'single variance (n-1 = 0)');
    is($single->median, 42, 'single median');

    my $reversed = $single->reverse;
    is_deeply($reversed->to_array, [42], 'single reverse');

    my $sorted = $single->sort;
    is_deeply($sorted->to_array, [42], 'single sort');
};

# ============================================
# Boundary conditions
# ============================================

subtest 'slice edge cases' => sub {
    my $v = Numeric::Vector::range(0, 10);

    # Full slice
    my $full = $v->slice(0, 10);
    is_deeply($full->to_array, [0,1,2,3,4,5,6,7,8,9], 'full slice');

    # Empty slice
    my $empty_slice = $v->slice(5, 0);
    is($empty_slice->len, 0, 'empty slice');

    # Single element slice
    my $single = $v->slice(5, 1);
    is_deeply($single->to_array, [5], 'single element slice');

    # Negative index
    my $neg = $v->slice(-3, 2);
    is_deeply($neg->to_array, [7, 8], 'negative start slice');

    # Last element
    my $last = $v->slice(-1, 1);
    is_deeply($last->to_array, [9], 'last element slice');
};

subtest 'clamp edge cases' => sub {
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);

    # Clamp with min == max
    my $c1 = $v->copy;
    $c1->clamp_inplace(3, 3);
    is_deeply($c1->to_array, [3, 3, 3, 3, 3], 'clamp to single value');

    # All values already in range
    my $c2 = Numeric::Vector::new([2, 3, 4]);
    $c2->clamp_inplace(1, 5);
    is_deeply($c2->to_array, [2, 3, 4], 'clamp no change');

    # Negative range
    my $c3 = Numeric::Vector::new([-10, 0, 10]);
    $c3->clamp_inplace(-5, 5);
    is_deeply($c3->to_array, [-5, 0, 5], 'clamp negative range');
};

# ============================================
# Numeric edge cases
# ============================================

subtest 'very small numbers' => sub {
    my $tiny = Numeric::Vector::new([1e-300, 2e-300, 3e-300]);
    ok($tiny->sum > 0, 'tiny sum is positive');
    approx_eq($tiny->sum, 6e-300, 'tiny sum value');
};

subtest 'very large numbers' => sub {
    my $huge = Numeric::Vector::new([1e100, 2e100, 3e100]);
    approx_eq($huge->sum / 1e100, 6, 'huge sum ratio');
    approx_eq($huge->mean / 1e100, 2, 'huge mean ratio');
};

subtest 'mixed positive and negative' => sub {
    my $mixed = Numeric::Vector::new([-100, 50, -25, 75]);
    is($mixed->sum, 0, 'mixed sum');
    is($mixed->min, -100, 'mixed min');
    is($mixed->max, 75, 'mixed max');
};

subtest 'zeros and ones patterns' => sub {
    my $zeros = Numeric::Vector::zeros(100);
    is($zeros->sum, 0, 'all zeros sum');
    is($zeros->product, 0, 'all zeros product');
    ok(!$zeros->any, 'zeros any');
    ok(!$zeros->all, 'zeros all');

    my $ones = Numeric::Vector::ones(100);
    is($ones->sum, 100, 'all ones sum');
    is($ones->product, 1, 'all ones product');
    ok($ones->any, 'ones any');
    ok($ones->all, 'ones all');
};

# ============================================
# Comparison operations edge cases
# ============================================

subtest 'comparison with self' => sub {
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);

    my $eq = $v->eq($v);
    is_deeply($eq->to_array, [1, 1, 1, 1, 1], 'eq with self');

    my $ne = $v->ne($v);
    is_deeply($ne->to_array, [0, 0, 0, 0, 0], 'ne with self');

    my $lt = $v->lt($v);
    is_deeply($lt->to_array, [0, 0, 0, 0, 0], 'lt with self');

    my $le = $v->le($v);
    is_deeply($le->to_array, [1, 1, 1, 1, 1], 'le with self');
};

subtest 'comparison all same' => sub {
    my $a = Numeric::Vector::fill(5, 3);
    my $b = Numeric::Vector::fill(5, 3);

    my $eq = $a->eq($b);
    ok($eq->all, 'all equal');

    my $c = Numeric::Vector::fill(5, 4);
    my $lt = $a->lt($c);
    ok($lt->all, 'all less than');
};

# ============================================
# Concatenation and combining
# ============================================

subtest 'concat operations' => sub {
    my $a = Numeric::Vector::new([1, 2, 3]);
    my $b = Numeric::Vector::new([4, 5, 6]);
    my $c = Numeric::Vector::new([7, 8, 9]);

    my $ab = $a->concat($b);
    is_deeply($ab->to_array, [1,2,3,4,5,6], 'concat two');

    my $abc = $a->concat($b)->concat($c);
    is_deeply($abc->to_array, [1,2,3,4,5,6,7,8,9], 'concat three chained');

    # Concat with empty
    my $empty = Numeric::Vector::new([]);
    my $ae = $a->concat($empty);
    is_deeply($ae->to_array, [1,2,3], 'concat with empty right');

    my $ea = $empty->concat($a);
    is_deeply($ea->to_array, [1,2,3], 'concat with empty left');
};

# ============================================
# Cumulative operations edge cases
# ============================================

subtest 'cumsum edge cases' => sub {
    my $single = Numeric::Vector::new([42]);
    is_deeply($single->cumsum->to_array, [42], 'cumsum single');

    my $neg = Numeric::Vector::new([-1, 2, -3, 4]);
    is_deeply($neg->cumsum->to_array, [-1, 1, -2, 2], 'cumsum with negatives');
};

subtest 'cumprod edge cases' => sub {
    my $with_zero = Numeric::Vector::new([1, 2, 0, 3, 4]);
    my $cp = $with_zero->cumprod;
    is_deeply($cp->to_array, [1, 2, 0, 0, 0], 'cumprod with zero');

    my $neg = Numeric::Vector::new([-1, 2, -3]);
    is_deeply($neg->cumprod->to_array, [-1, -2, 6], 'cumprod with negatives');
};

subtest 'diff edge cases' => sub {
    my $single = Numeric::Vector::new([42]);
    my $diff = $single->diff;
    is($diff->len, 0, 'diff of single element');

    my $two = Numeric::Vector::new([10, 7]);
    is_deeply($two->diff->to_array, [-3], 'diff of two elements');

    my $constant = Numeric::Vector::fill(5, 42);
    my $cdiff = $constant->diff;
    ok($cdiff->sum == 0, 'diff of constant is all zeros');
};

# ============================================
# Sort and search edge cases
# ============================================

subtest 'sort edge cases' => sub {
    my $already_sorted = Numeric::Vector::range(0, 10);
    is_deeply($already_sorted->sort->to_array, [0,1,2,3,4,5,6,7,8,9], 'sort already sorted');

    my $reverse_sorted = Numeric::Vector::new([9,8,7,6,5,4,3,2,1,0]);
    is_deeply($reverse_sorted->sort->to_array, [0,1,2,3,4,5,6,7,8,9], 'sort reverse');

    my $duplicates = Numeric::Vector::new([3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5]);
    my $sorted = $duplicates->sort;
    is($sorted->get(0), 1, 'sort duplicates first');
    is($sorted->get(1), 1, 'sort duplicates second');
    is($sorted->get($sorted->len - 1), 9, 'sort duplicates last');
};

subtest 'argsort edge cases' => sub {
    my $v = Numeric::Vector::new([30, 10, 20]);
    my $idx = $v->argsort;
    is_deeply($idx->to_array, [1, 2, 0], 'argsort basic');

    my $dup = Numeric::Vector::new([3, 1, 3, 1]);
    my $didx = $dup->argsort;
    # First two should be indices of 1s, last two indices of 3s
    ok($dup->get($didx->get(0)) == 1, 'argsort dup first is 1');
    ok($dup->get($didx->get(1)) == 1, 'argsort dup second is 1');
    ok($dup->get($didx->get(2)) == 3, 'argsort dup third is 3');
};

subtest 'median edge cases' => sub {
    my $odd = Numeric::Vector::new([5, 1, 3]);
    is($odd->median, 3, 'median odd count');

    my $even = Numeric::Vector::new([4, 1, 3, 2]);
    is($even->median, 2.5, 'median even count');

    my $two = Numeric::Vector::new([10, 20]);
    is($two->median, 15, 'median two elements');
};

# ============================================
# Where/filter edge cases
# ============================================

subtest 'where edge cases' => sub {
    my $v = Numeric::Vector::range(0, 10);

    # All match
    my $all_mask = Numeric::Vector::ones(10);
    is_deeply($v->where($all_mask)->to_array, [0,1,2,3,4,5,6,7,8,9], 'where all match');

    # None match
    my $none_mask = Numeric::Vector::zeros(10);
    is($v->where($none_mask)->len, 0, 'where none match');

    # Single match
    my $one_mask = Numeric::Vector::new([0,0,0,0,1,0,0,0,0,0]);
    is_deeply($v->where($one_mask)->to_array, [4], 'where single match');
};

# ============================================
# Copy independence
# ============================================

subtest 'copy independence' => sub {
    my $orig = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $copy = $orig->copy;

    $copy->set(0, 999);
    is($orig->get(0), 1, 'original unchanged after copy modification');
    is($copy->get(0), 999, 'copy has new value');

    $orig->scale_inplace(2);
    is($orig->get(1), 4, 'original scaled');
    is($copy->get(1), 2, 'copy not affected by original scaling');
};

done_testing;
