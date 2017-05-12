use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Scientist.pm',
    'lib/Scientist.pod',
    't/00-compile.t',
    't/context.t',
    't/enabled.t',
    't/experiment_name.t',
    't/lib/Named/Scientist.pm',
    't/lib/Publishing/Scientist.pm',
    't/publish.t',
    't/random_order.t',
    't/regression/16.t',
    't/result.t',
    't/wantarray.t'
);

notabs_ok($_) foreach @files;
done_testing;
