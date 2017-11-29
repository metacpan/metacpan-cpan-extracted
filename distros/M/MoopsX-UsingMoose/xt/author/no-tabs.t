use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MoopsX/TraitFor/Parser/UsingMoose.pm',
    'lib/MoopsX/UsingMoose.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/corpus/lib/TestFor/MoopsXUsingMoose.pm'
);

notabs_ok($_) foreach @files;
done_testing;
