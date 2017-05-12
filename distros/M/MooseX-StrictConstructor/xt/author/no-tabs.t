use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MooseX/StrictConstructor.pm',
    'lib/MooseX/StrictConstructor/Trait/Class.pm',
    'lib/MooseX/StrictConstructor/Trait/Method/Constructor.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t',
    't/instance.t',
    't/no_build.t'
);

notabs_ok($_) foreach @files;
done_testing;
