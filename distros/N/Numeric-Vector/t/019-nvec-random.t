#!/usr/bin/perl
use strict;
use warnings;
use Test2::Bundle::Numerical qw(:all);
use Numeric::Vector;

# Test Numeric::Vector::random function

subtest 'random returns correct size' => sub {
    my $r = Numeric::Vector::random(10);
    is($r->len, 10, 'random(10) has 10 elements');
    
    my $r2 = Numeric::Vector::random(100);
    is($r2->len, 100, 'random(100) has 100 elements');
};

subtest 'random values in range [0, 1)' => sub {
    my $r = Numeric::Vector::random(1000);
    my $min = $r->min;
    my $max = $r->max;
    
    ok($min >= 0, 'min value >= 0');
    ok($max < 1, 'max value < 1');
};

subtest 'random distribution properties' => sub {
    my $r = Numeric::Vector::random(10000);
    my $mean = $r->mean;
    
    # For uniform [0,1), expected mean is 0.5
    ok($mean > 0.45 && $mean < 0.55, "mean ($mean) is near 0.5");
};

subtest 'random variance' => sub {
    my $r = Numeric::Vector::random(10000);
    my $mean = $r->mean;
    
    # Calculate variance manually
    my $sum_sq = 0;
    for my $i (0 .. $r->len - 1) {
        my $diff = $r->get($i) - $mean;
        $sum_sq += $diff * $diff;
    }
    my $variance = $sum_sq / $r->len;
    
    # For uniform [0,1), expected variance is 1/12 ≈ 0.0833
    ok($variance > 0.07 && $variance < 0.1, "variance ($variance) is near 1/12");
};

subtest 'multiple random calls produce different values' => sub {
    my $r1 = Numeric::Vector::random(100);
    my $r2 = Numeric::Vector::random(100);
    
    # Compare sums - they should be different
    my $sum1 = $r1->sum;
    my $sum2 = $r2->sum;
    
    ok($sum1 != $sum2, 'different random calls produce different values');
};

subtest 'random with small size' => sub {
    my $r = Numeric::Vector::random(1);
    is($r->len, 1, 'random(1) works');
    my $val = $r->get(0);
    ok($val >= 0 && $val < 1, 'single random value in range');
};

subtest 'random values are well distributed' => sub {
    my $r = Numeric::Vector::random(1000);
    
    # Count values in quartiles
    my @quartiles = (0, 0, 0, 0);
    for my $i (0 .. $r->len - 1) {
        my $v = $r->get($i);
        if ($v < 0.25) { $quartiles[0]++ }
        elsif ($v < 0.5) { $quartiles[1]++ }
        elsif ($v < 0.75) { $quartiles[2]++ }
        else { $quartiles[3]++ }
    }
    
    # Each quartile should have roughly 250 values (allow 150-350 range)
    for my $i (0 .. 3) {
        ok($quartiles[$i] > 150 && $quartiles[$i] < 350, 
           "quartile $i has reasonable count: $quartiles[$i]");
    }
};

done_testing;
