use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MooX/Const.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/10-has.t',
    't/20-moo.t',
    't/21-moox-typetiny.t',
    't/22-moo-coerce.t',
    't/23-moo-mungehas.t',
    't/30-strict.t',
    't/31-strict.t',
    't/40-moose.t',
    't/lib/MooTest.pm',
    't/lib/MooTest/MungeHas.pm',
    't/lib/MooTest/Strict.pm',
    't/lib/MooseTest.pm'
);

notabs_ok($_) foreach @files;
done_testing;
