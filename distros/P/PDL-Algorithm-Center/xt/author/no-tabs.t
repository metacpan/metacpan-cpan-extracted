use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/PDL/Algorithm/Center.pm',
    'lib/PDL/Algorithm/Center/Failure.pm',
    'lib/PDL/Algorithm/Center/Types.pm',
    't/00-compile.t',
    't/00-load.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/sigma_clip.t',
    't/types.t'
);

notabs_ok($_) foreach @files;
done_testing;
