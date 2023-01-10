use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/PDLx/Mask.pm',
    'lib/PDLx/MaskedData.pm',
    'lib/PDLx/Role/RestrictedPDL.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/data.t',
    't/lib/fix_devel_cover.pm',
    't/mask.t'
);

notabs_ok($_) foreach @files;
done_testing;
