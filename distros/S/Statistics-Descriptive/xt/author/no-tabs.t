use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Statistics/Descriptive.pm',
    'lib/Statistics/Descriptive/Smoother.pm',
    'lib/Statistics/Descriptive/Smoother/Exponential.pm',
    'lib/Statistics/Descriptive/Smoother/Weightedexponential.pm',
    't/00-compile.t',
    't/00-load.t',
    't/boilerplate.t',
    't/descr.t',
    't/descr_smooth_methods.t',
    't/freq_distribution-1-rt-34999.t',
    't/lib/Utils.pm',
    't/median_absolute_deviation.t',
    't/mode.t',
    't/outliers.t',
    't/quantile.t',
    't/smoother.t',
    't/smoother_exponential.t',
    't/smoother_weightedexponential.t'
);

notabs_ok($_) foreach @files;
done_testing;
