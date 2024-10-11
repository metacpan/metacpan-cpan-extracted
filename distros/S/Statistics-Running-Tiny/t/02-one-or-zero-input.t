#!perl -T
use 5.006;

use strict;
use warnings;

use Statistics::Running::Tiny;
use Test::More;

our $VERSION = '0.04';

my $num_tests = 0;

my $RU1 = Statistics::Running::Tiny->new();
$RU1->add(1);
is($RU1->get_N(), 1, "N=".$RU1->get_N()); $num_tests++;
ok(defined($RU1->mean()), "mean is defined: ".$RU1->mean()); $num_tests++;
ok(defined($RU1->min()), "min is defined: ".$RU1->min()); $num_tests++;
ok(defined($RU1->max()), "max is defined: ".$RU1->max()); $num_tests++;
ok(defined($RU1->sum()), "sum is defined: ".$RU1->sum()); $num_tests++;
ok(defined($RU1->abs_sum()), "abs_sum is defined: ".$RU1->abs_sum()); $num_tests++;
ok(defined($RU1->standard_deviation()), "standard_deviation is defined: ".$RU1->standard_deviation()); $num_tests++;
ok(defined($RU1->skewness()), "skewness is defined: ".$RU1->skewness()); $num_tests++;
ok(defined($RU1->kurtosis()), "kurtosis is defined: ".$RU1->kurtosis()); $num_tests++;

done_testing($num_tests);
