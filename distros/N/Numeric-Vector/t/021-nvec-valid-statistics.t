#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical qw(:all);
use lib 't/lib';

use Numeric::Vector;

if (is_quadmath()) {
    diag("Testing with quadmath (128-bit precision)");
}

# ============================================
# Statistics Workflow Integration Tests
# ============================================

subtest 'basic statistics on known data' => sub {
    # Simple dataset: 1, 2, 3, 4, 5
    my $data = Numeric::Vector::new([1, 2, 3, 4, 5]);

    within_tolerance($data->sum(), 15, 'sum = 15');
    within_tolerance($data->mean(), 3, 'mean = 3');
    within_tolerance($data->min(), 1, 'min = 1');
    within_tolerance($data->max(), 5, 'max = 5');

    # Variance = ((1-3)^2 + (2-3)^2 + (3-3)^2 + (4-3)^2 + (5-3)^2) / 4 = 10/4 = 2.5
    within_tolerance($data->variance(), 2.5, 'variance = 2.5');

    # Std = sqrt(2.5) ≈ 1.5811
    within_tolerance($data->std(), sqrt(2.5), 'std = sqrt(2.5)');
};

subtest 'median calculation' => sub {
    # Odd length
    my $odd = Numeric::Vector::new([3, 1, 4, 1, 5]);
    within_tolerance($odd->median(), 3, 'median of odd-length [3,1,4,1,5] = 3');

    # Even length - average of two middle values
    my $even = Numeric::Vector::new([1, 2, 3, 4]);
    within_tolerance($even->median(), 2.5, 'median of even-length [1,2,3,4] = 2.5');
};

subtest 'argmin and argmax' => sub {
    my $data = Numeric::Vector::new([5, 2, 8, 1, 9, 3]);

    is($data->argmin(), 3, 'argmin finds index of 1');
    is($data->argmax(), 4, 'argmax finds index of 9');
};

subtest 'cumulative operations' => sub {
    my $data = Numeric::Vector::new([1, 2, 3, 4]);

    my $csum = $data->cumsum();
    my $expected_sum = Numeric::Vector::new([1, 3, 6, 10]);
    ok(vec_approx_eq($csum, $expected_sum), 'cumsum [1,2,3,4] = [1,3,6,10]');

    my $cprod = $data->cumprod();
    my $expected_prod = Numeric::Vector::new([1, 2, 6, 24]);
    ok(vec_approx_eq($cprod, $expected_prod), 'cumprod [1,2,3,4] = [1,2,6,24]');
};

subtest 'diff operation' => sub {
    my $data = Numeric::Vector::new([1, 4, 9, 16, 25]);  # squares

    my $d = $data->diff();
    my $expected = Numeric::Vector::new([3, 5, 7, 9]);  # odd numbers (differences of squares)
    ok(vec_approx_eq($d, $expected), 'diff of squares gives odd numbers');
};

subtest 'sorting and argsort' => sub {
    my $data = Numeric::Vector::new([3.5, 1.2, 4.8, 2.1]);

    my $sorted = $data->sort();
    my $expected = Numeric::Vector::new([1.2, 2.1, 3.5, 4.8]);
    ok(vec_approx_eq($sorted, $expected), 'sort works correctly');

    my $indices = $data->argsort();
    # Original: [3.5, 1.2, 4.8, 2.1]
    # Sorted:   [1.2, 2.1, 3.5, 4.8]
    # Indices:  [1,   3,   0,   2]
    is($indices->get(0), 1, 'argsort: smallest at index 1');
    is($indices->get(3), 2, 'argsort: largest at index 2');
};

subtest 'z-score normalization workflow' => sub {
    my $data = Numeric::Vector::new([10, 20, 30, 40, 50]);

    my $mean = $data->mean();
    my $std = $data->std();

    # z = (x - mean) / std
    my $centered = $data->add_scalar(-$mean);
    my $zscore = $centered->scale(1.0 / $std);

    within_tolerance($zscore->mean(), 0, 'z-scores have mean ≈ 0');
    within_tolerance($zscore->std(), 1, 'z-scores have std ≈ 1', get_tolerance(0));
};

subtest 'product reduction' => sub {
    my $data = Numeric::Vector::new([2, 3, 4]);
    within_tolerance($data->product(), 24, 'product of [2,3,4] = 24');

    my $ones = Numeric::Vector::ones(10);
    within_tolerance($ones->product(), 1, 'product of ones = 1');
};

subtest 'large dataset statistics' => sub {
    # Test with larger dataset for numerical stability
    my $n = 10000;
    my $data = Numeric::Vector::range(1, $n + 1);  # 1 to 10000

    # Sum = n*(n+1)/2
    my $expected_sum = $n * ($n + 1) / 2;
    within_tolerance($data->sum(), $expected_sum, "sum of 1..$n");

    # Mean = (n+1)/2
    my $expected_mean = ($n + 1) / 2;
    within_tolerance($data->mean(), $expected_mean, "mean of 1..$n");
};

subtest 'weighted statistics simulation' => sub {
    my $values = Numeric::Vector::new([10, 20, 30]);
    my $weights = Numeric::Vector::new([1, 2, 1]);  # Weight 20 twice as much

    # Weighted mean = sum(v*w) / sum(w)
    my $weighted = $values->mul($weights);
    my $weighted_mean = $weighted->sum() / $weights->sum();

    # (10*1 + 20*2 + 30*1) / 4 = 80/4 = 20
    within_tolerance($weighted_mean, 20, 'weighted mean calculation');
};

done_testing();
