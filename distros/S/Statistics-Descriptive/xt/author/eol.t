use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Statistics/Descriptive.pm',
    'lib/Statistics/Descriptive/Full.pm',
    'lib/Statistics/Descriptive/Smoother.pm',
    'lib/Statistics/Descriptive/Smoother/Exponential.pm',
    'lib/Statistics/Descriptive/Smoother/Weightedexponential.pm',
    'lib/Statistics/Descriptive/Sparse.pm',
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
    't/smoother_weightedexponential.t',
    't/summary.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
