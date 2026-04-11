#!/usr/bin/env perl
# Test Numeric::Vector array operations: any, all, reverse, concat, where, count
use strict;
use warnings;
use Test2::Bundle::Numerical qw(:all);
use Numeric::Vector;

if (is_quadmath()) {
    diag("Testing with quadmath (128-bit precision)");
}

subtest 'any - some true values' => sub {
    my $v = Numeric::Vector::new([0, 0, 1, 0, 0]);
    ok($v->any, 'any returns true when one value is nonzero');
};

subtest 'any - all zeros' => sub {
    my $v = Numeric::Vector::new([0, 0, 0, 0]);
    ok(!$v->any, 'any returns false when all values are zero');
};

subtest 'any - all nonzero' => sub {
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);
    ok($v->any, 'any returns true when all values are nonzero');
};

subtest 'any - with negatives' => sub {
    my $v = Numeric::Vector::new([0, 0, -1, 0]);
    ok($v->any, 'any considers negative values as true');
};

subtest 'all - all true' => sub {
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);
    ok($v->all, 'all returns true when all values are nonzero');
};

subtest 'all - one zero' => sub {
    my $v = Numeric::Vector::new([1, 2, 0, 4, 5]);
    ok(!$v->all, 'all returns false when any value is zero');
};

subtest 'all - all zeros' => sub {
    my $v = Numeric::Vector::new([0, 0, 0]);
    ok(!$v->all, 'all returns false when all values are zero');
};

subtest 'all - with negatives' => sub {
    my $v = Numeric::Vector::new([-1, -2, -3]);
    ok($v->all, 'all considers negative values as true');
};

subtest 'reverse - basic' => sub {
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $rev = $v->reverse;

    is_deeply($rev->to_array, [5, 4, 3, 2, 1], 'reverse works');
    is_deeply($v->to_array, [1, 2, 3, 4, 5], 'original unchanged');
};

subtest 'reverse - single element' => sub {
    my $v = Numeric::Vector::new([42]);
    my $rev = $v->reverse;

    is_deeply($rev->to_array, [42], 'reverse of single element');
};

subtest 'reverse - two elements' => sub {
    my $v = Numeric::Vector::new([1, 2]);
    my $rev = $v->reverse;

    is_deeply($rev->to_array, [2, 1], 'reverse of two elements');
};

subtest 'reverse twice returns original order' => sub {
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $rev = $v->reverse->reverse;

    is_deeply($rev->to_array, [1, 2, 3, 4, 5], 'reverse twice = original');
};

subtest 'concat - basic' => sub {
    my $a = Numeric::Vector::new([1, 2, 3]);
    my $b = Numeric::Vector::new([4, 5, 6]);

    my $c = $a->concat($b);
    is($c->len, 6, 'concat length is sum of lengths');
    is_deeply($c->to_array, [1, 2, 3, 4, 5, 6], 'concat values correct');

    is_deeply($a->to_array, [1, 2, 3], 'original a unchanged');
    is_deeply($b->to_array, [4, 5, 6], 'original b unchanged');
};

subtest 'concat - empty vector' => sub {
    my $a = Numeric::Vector::new([1, 2, 3]);
    my $empty = Numeric::Vector::new([]);

    my $c1 = $a->concat($empty);
    is_deeply($c1->to_array, [1, 2, 3], 'concat with empty on right');

    my $c2 = $empty->concat($a);
    is_deeply($c2->to_array, [1, 2, 3], 'concat with empty on left');
};

subtest 'concat - different sizes' => sub {
    my $a = Numeric::Vector::new([1, 2]);
    my $b = Numeric::Vector::new([3, 4, 5, 6, 7]);

    my $c = $a->concat($b);
    is_deeply($c->to_array, [1, 2, 3, 4, 5, 6, 7], 'concat different sizes');
};

subtest 'where - basic masking' => sub {
    my $v = Numeric::Vector::new([10, 20, 30, 40, 50]);
    my $mask = Numeric::Vector::new([1, 0, 1, 0, 1]);

    my $result = $v->where($mask);
    is($result->len, 3, 'where returns masked elements');
    is_deeply($result->to_array, [10, 30, 50], 'where values correct');
};

subtest 'where - all true' => sub {
    my $v = Numeric::Vector::new([1, 2, 3]);
    my $mask = Numeric::Vector::new([1, 1, 1]);

    my $result = $v->where($mask);
    is_deeply($result->to_array, [1, 2, 3], 'where with all true mask');
};

subtest 'where - all false' => sub {
    my $v = Numeric::Vector::new([1, 2, 3]);
    my $mask = Numeric::Vector::new([0, 0, 0]);

    my $result = $v->where($mask);
    is($result->len, 0, 'where with all false mask returns empty');
};

subtest 'where - with comparison result' => sub {
    my $v = Numeric::Vector::new([1, 5, 10, 15, 20]);
    my $mask = $v->gt(7);  # Elements > 7

    my $result = $v->where($mask);
    is_deeply($result->to_array, [10, 15, 20], 'where with comparison mask');
};

subtest 'count - basic' => sub {
    my $v = Numeric::Vector::new([1, 0, 1, 0, 1, 0, 0, 1]);
    my $c = $v->count;

    is($c, 4, 'count returns number of nonzero elements');
};

subtest 'count - all zeros' => sub {
    my $v = Numeric::Vector::new([0, 0, 0, 0]);
    my $c = $v->count;

    is($c, 0, 'count of all zeros is 0');
};

subtest 'count - all nonzero' => sub {
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $c = $v->count;

    is($c, 5, 'count of all nonzero equals length');
};

subtest 'count - negative values' => sub {
    my $v = Numeric::Vector::new([-1, 0, 1, 0, -2]);
    my $c = $v->count;

    is($c, 3, 'count includes negative values');
};

subtest 'combined operations: where and count' => sub {
    my $v = Numeric::Vector::new([1, 5, 10, 15, 20, 25, 30]);

    # Elements > 10
    my $mask = $v->gt(10);
    my $filtered = $v->where($mask);

    is($mask->count, 4, 'count of elements > 10');
    is_deeply($filtered->to_array, [15, 20, 25, 30], 'filtered elements');
};

subtest 'combined: filter, reverse, concat' => sub {
    my $a = Numeric::Vector::new([1, 2, 3]);
    my $b = Numeric::Vector::new([4, 5, 6]);

    my $combined = $a->reverse->concat($b);
    is_deeply($combined->to_array, [3, 2, 1, 4, 5, 6], 'combined operations');
};

done_testing();
