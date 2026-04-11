#!/usr/bin/env perl
# Test Numeric::Vector floating-point checks: isnan, isinf, isfinite
use strict;
use warnings;
use Test2::Bundle::Numerical qw(:all);
use Numeric::Vector;

if (is_quadmath()) {
    diag("Testing with quadmath (128-bit precision)");
}

# Helper to get special values
my $nan = 9**9**9 - 9**9**9;  # NaN
my $inf = 9**9**9;            # Infinity
my $ninf = -9**9**9;          # Negative infinity

subtest 'isnan - basic' => sub {
    my $v = Numeric::Vector::new([1, $nan, 3, $nan, 5]);
    my $result = $v->isnan;

    is($result->len, 5, 'isnan result has correct length');
    my @vals = @{$result->to_array};
    is($vals[0], 0, 'isnan: 1 is not NaN');
    is($vals[1], 1, 'isnan: NaN is NaN');
    is($vals[2], 0, 'isnan: 3 is not NaN');
    is($vals[3], 1, 'isnan: NaN is NaN');
    is($vals[4], 0, 'isnan: 5 is not NaN');
};

subtest 'isnan - no NaN values' => sub {
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $result = $v->isnan;

    is($result->count, 0, 'no NaN values found');
};

subtest 'isnan - all NaN' => sub {
    my $v = Numeric::Vector::new([$nan, $nan, $nan]);
    my $result = $v->isnan;

    is($result->count, 3, 'all values are NaN');
};

subtest 'isnan - infinity is not NaN' => sub {
    my $v = Numeric::Vector::new([$inf, $ninf, 0]);
    my $result = $v->isnan;

    my @vals = @{$result->to_array};
    is($vals[0], 0, 'isnan: +inf is not NaN');
    is($vals[1], 0, 'isnan: -inf is not NaN');
    is($vals[2], 0, 'isnan: 0 is not NaN');
};

subtest 'isinf - basic' => sub {
    my $v = Numeric::Vector::new([1, $inf, 3, $ninf, 5]);
    my $result = $v->isinf;

    is($result->len, 5, 'isinf result has correct length');
    my @vals = @{$result->to_array};
    is($vals[0], 0, 'isinf: 1 is not inf');
    is($vals[1], 1, 'isinf: +inf is inf');
    is($vals[2], 0, 'isinf: 3 is not inf');
    is($vals[3], 1, 'isinf: -inf is inf');
    is($vals[4], 0, 'isinf: 5 is not inf');
};

subtest 'isinf - no infinite values' => sub {
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $result = $v->isinf;

    is($result->count, 0, 'no infinite values found');
};

subtest 'isinf - NaN is not infinite' => sub {
    my $v = Numeric::Vector::new([$nan, 0, 1]);
    my $result = $v->isinf;

    my @vals = @{$result->to_array};
    is($vals[0], 0, 'isinf: NaN is not infinite');
    is($vals[1], 0, 'isinf: 0 is not infinite');
    is($vals[2], 0, 'isinf: 1 is not infinite');
};

subtest 'isfinite - basic' => sub {
    my $v = Numeric::Vector::new([1, $inf, $nan, $ninf, 5]);
    my $result = $v->isfinite;

    is($result->len, 5, 'isfinite result has correct length');
    my @vals = @{$result->to_array};
    is($vals[0], 1, 'isfinite: 1 is finite');
    is($vals[1], 0, 'isfinite: +inf is not finite');
    is($vals[2], 0, 'isfinite: NaN is not finite');
    is($vals[3], 0, 'isfinite: -inf is not finite');
    is($vals[4], 1, 'isfinite: 5 is finite');
};

subtest 'isfinite - all finite' => sub {
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $result = $v->isfinite;

    is($result->count, 5, 'all values are finite');
};

subtest 'isfinite - none finite' => sub {
    my $v = Numeric::Vector::new([$nan, $inf, $ninf]);
    my $result = $v->isfinite;

    is($result->count, 0, 'no finite values');
};

subtest 'isfinite - zero and negative' => sub {
    my $v = Numeric::Vector::new([0, -1, -1e100, 1e100]);
    my $result = $v->isfinite;

    my @vals = @{$result->to_array};
    is($vals[0], 1, 'isfinite: 0 is finite');
    is($vals[1], 1, 'isfinite: -1 is finite');
    is($vals[2], 1, 'isfinite: -1e100 is finite');
    is($vals[3], 1, 'isfinite: 1e100 is finite');
};

subtest 'combined: filter out non-finite' => sub {
    my $v = Numeric::Vector::new([1, $nan, 3, $inf, 5, $ninf, 7]);

    my $finite_mask = $v->isfinite;
    my $finite_only = $v->where($finite_mask);

    is($finite_only->len, 4, 'filtered to 4 finite values');
    is_deeply($finite_only->to_array, [1, 3, 5, 7], 'correct finite values');
};

subtest 'combined: count special values' => sub {
    my $v = Numeric::Vector::new([1, $nan, $inf, 4, $ninf, $nan, 7]);

    is($v->isnan->count, 2, '2 NaN values');
    is($v->isinf->count, 2, '2 infinite values');
    is($v->isfinite->count, 3, '3 finite values');
};

subtest 'operations producing special values' => sub {
    my $a = Numeric::Vector::new([0, 1, -1, 0]);
    my $b = Numeric::Vector::new([0, 0, 0, 1]);

    my $result = $a->div($b);  # 0/0=NaN, 1/0=inf, -1/0=-inf, 0/1=0
    my @vals = @{$result->to_array};

    ok($result->isnan->to_array->[0], '0/0 produces NaN');
    ok($result->isinf->to_array->[1], '1/0 produces inf');
    ok($result->isinf->to_array->[2], '-1/0 produces inf');
    ok($result->isfinite->to_array->[3], '0/1 is finite');
};

done_testing();
