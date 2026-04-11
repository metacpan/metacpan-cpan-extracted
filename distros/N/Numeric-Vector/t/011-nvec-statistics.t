#!/usr/bin/env perl
# Test Numeric::Vector statistical functions: variance, std, median
use strict;
use warnings;
use Test2::Bundle::Numerical qw(:all);
use Numeric::Vector;

if (is_quadmath()) {
    diag("Testing with quadmath (128-bit precision)");
}

my $tol = get_tolerance();

subtest 'variance - basic' => sub {
    # Variance of [1, 2, 3, 4, 5] using SAMPLE variance (n-1 divisor)
    # Mean = 3, deviations = [-2, -1, 0, 1, 2]
    # Squared deviations = [4, 1, 0, 1, 4] = 10
    # Sample Variance = 10/(5-1) = 2.5
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $var = $v->variance;

    ok(approx_eq($var, 2.5, $tol), 'variance of [1,2,3,4,5] is 2.5 (sample)');
};

subtest 'variance - uniform values' => sub {
    my $v = Numeric::Vector::new([5, 5, 5, 5, 5]);
    my $var = $v->variance;

    ok(approx_eq($var, 0, $tol), 'variance of uniform values is 0');
};

subtest 'variance - two values' => sub {
    # [0, 10]: mean = 5, deviations = [-5, 5], squared = [25, 25] = 50
    # Sample variance = 50 / (2-1) = 50
    my $v = Numeric::Vector::new([0, 10]);
    my $var = $v->variance;

    ok(approx_eq($var, 50, $tol), 'variance of [0,10] is 50 (sample)');
};

subtest 'variance - large spread' => sub {
    my $v = Numeric::Vector::new([0, 100, 200, 300, 400]);
    # Mean = 200, deviations = [-200, -100, 0, 100, 200]
    # Squared = [40000, 10000, 0, 10000, 40000] = 100000
    # Sample Variance = 100000/(5-1) = 25000
    my $var = $v->variance;

    ok(approx_eq($var, 25000, $tol), 'variance of [0,100,200,300,400] is 25000 (sample)');
};

subtest 'std - basic' => sub {
    # std of [1, 2, 3, 4, 5] = sqrt(sample_var) = sqrt(2.5) ≈ 1.581
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $std = $v->std;

    ok(approx_eq($std, sqrt(2.5), $tol), 'std of [1,2,3,4,5] is sqrt(2.5)');
};

subtest 'std - uniform values' => sub {
    my $v = Numeric::Vector::new([7, 7, 7, 7]);
    my $std = $v->std;

    ok(approx_eq($std, 0, $tol), 'std of uniform values is 0');
};

subtest 'std - two values' => sub {
    # [0, 10]: sample_var = 50, std = sqrt(50) ≈ 7.071
    my $v = Numeric::Vector::new([0, 10]);
    my $std = $v->std;

    ok(approx_eq($std, sqrt(50), $tol), 'std of [0,10] is sqrt(50)');
};

subtest 'std - negative values' => sub {
    my $v = Numeric::Vector::new([-5, -3, -1, 1, 3, 5]);
    # Mean = 0, squared deviations = [25, 9, 1, 1, 9, 25] = 70
    # Sample Variance = 70/(6-1) = 14
    my $std = $v->std;
    my $expected = sqrt(14);

    ok(approx_eq($std, $expected, $tol), 'std of symmetric values around 0');
};

subtest 'median - odd count' => sub {
    my $v = Numeric::Vector::new([1, 3, 5, 7, 9]);
    my $med = $v->median;

    is($med, 5, 'median of [1,3,5,7,9] is 5');
};

subtest 'median - even count' => sub {
    my $v = Numeric::Vector::new([1, 3, 5, 7]);
    # Median = (3 + 5) / 2 = 4
    my $med = $v->median;

    ok(approx_eq($med, 4, $tol), 'median of [1,3,5,7] is 4');
};

subtest 'median - unsorted input' => sub {
    my $v = Numeric::Vector::new([5, 1, 9, 3, 7]);
    # Sorted: [1, 3, 5, 7, 9]
    my $med = $v->median;

    is($med, 5, 'median of unsorted [5,1,9,3,7] is 5');
};

subtest 'median - single value' => sub {
    my $v = Numeric::Vector::new([42]);
    my $med = $v->median;

    is($med, 42, 'median of single value is that value');
};

subtest 'median - two values' => sub {
    my $v = Numeric::Vector::new([10, 20]);
    my $med = $v->median;

    ok(approx_eq($med, 15, $tol), 'median of [10,20] is 15');
};

subtest 'median - negative values' => sub {
    my $v = Numeric::Vector::new([-5, -1, 0, 1, 5]);
    my $med = $v->median;

    is($med, 0, 'median of [-5,-1,0,1,5] is 0');
};

subtest 'median - floats' => sub {
    my $v = Numeric::Vector::new([1.1, 2.2, 3.3, 4.4, 5.5]);
    my $med = $v->median;

    ok(approx_eq($med, 3.3, $tol), 'median of floats');
};

subtest 'std and variance consistency' => sub {
    my $v = Numeric::Vector::new([2, 4, 4, 4, 5, 5, 7, 9]);
    my $var = $v->variance;
    my $std = $v->std;

    ok(approx_eq($std * $std, $var, $tol), 'std^2 equals variance');
};

subtest 'statistics with large vector' => sub {
    # 1 to 100
    my @data = 1..100;
    my $v = Numeric::Vector::new(\@data);

    # Mean = 50.5
    my $mean = $v->mean;
    ok(approx_eq($mean, 50.5, $tol), 'mean of 1..100 is 50.5');

    my $var = $v->variance;
    # Sample variance for 1..n = n*(n+1)*(2n+1)/6 / (n-1) - mean^2 * n/(n-1)
    # Simpler: sample variance = (n^2 - 1) / 12 * n/(n-1) = 841.666...
    # Actually: sum of squares = n*(n+1)*(2n+1)/6 = 338350
    # mean = 50.5, so sum of (x-mean)^2 = 338350 - 100*50.5^2 = 338350 - 255025 = 83325
    # sample variance = 83325 / 99 = 841.666...
    ok(approx_eq($var, 83325.0/99.0, $tol), 'variance of 1..100 (sample)');

    my $med = $v->median;
    ok(approx_eq($med, 50.5, $tol), 'median of 1..100 is 50.5');
};

subtest 'relationship: variance, std, mean' => sub {
    my $v = Numeric::Vector::new([10, 20, 30, 40, 50]);

    my $mean = $v->mean;
    my $var = $v->variance;
    my $std = $v->std;

    ok(approx_eq($mean, 30, $tol), 'mean is 30');
    ok($std > 0, 'std is positive');
    ok(approx_eq($std, sqrt($var), $tol), 'std = sqrt(variance)');
};

done_testing();
