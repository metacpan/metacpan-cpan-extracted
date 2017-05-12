#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
BEGIN { push(@INC, "lib", "t"); }
use TestHelper;

my $mturk = TestHelper->new;

plan tests => 13;
ok( $mturk, "Created client");

my $response;

$response = $mturk->GetRequesterStatistic(
    Statistic => 'EstimatedRewardLiability', Count => 10, TimePeriod => "LifeToDate"
);

ok(defined($response->{DataPoint}[0]{Date}[0]), "GetRequesterStatistic has DataPoint");
ok(defined($response->{DataPoint}[0]{DoubleValue}[0]), "GetRequesterStatistic has DoubleValue");

$response = $mturk->GetRequesterStatistic([
     { Statistic => 'EstimatedRewardLiability', Count => 10, TimePeriod => "LifeToDate" },
     { Statistic => 'EstimatedTotalLiability', Count => 10, TimePeriod => "LifeToDate" }
]);

ok($#{$response} == 1, "GetRequesterStatistic (Batch)");
foreach my $stat (@$response) {
    ok(defined($stat->{DataPoint}[0]{Date}[0]), "GetRequesterStatistic has DataPoint");
    ok(defined($stat->{DataPoint}[0]{DoubleValue}[0]), "GetRequesterStatistic has DoubleValue");
}

$response = $mturk->GetRequesterStatistic(
     GetRequesterStatistic => [ 
         { Statistic => 'EstimatedRewardLiability', Count => 10, TimePeriod => "LifeToDate" },
         { Statistic => 'EstimatedTotalLiability', Count => 10, TimePeriod => "LifeToDate" }
     ]
);

ok($#{$response} == 1, "GetRequesterStatistic (Batch call style 2)");
foreach my $stat (@$response) {
    ok(defined($stat->{DataPoint}[0]{Date}[0]), "GetRequesterStatistic has DataPoint");
    ok(defined($stat->{DataPoint}[0]{DoubleValue}[0]), "GetRequesterStatistic has DoubleValue");
}
