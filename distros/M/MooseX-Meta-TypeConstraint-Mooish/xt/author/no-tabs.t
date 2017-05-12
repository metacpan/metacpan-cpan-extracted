use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.13

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MooseX/Meta/TypeConstraint/Mooish.pm',
    'lib/MooseX/TraitFor/Meta/TypeConstraint/Mooish.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/000-report-versions-tiny.t',
    't/isa-mooish.t',
    't/public-interface.t'
);

notabs_ok($_) foreach @files;
done_testing;
