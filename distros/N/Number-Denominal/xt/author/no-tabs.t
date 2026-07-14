use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Number/Denominal.pm',
    't/00-compile.t',
    't/00-load.t',
    't/01-string.t',
    't/02-list.t',
    't/03-hashref.t',
    't/04-precision.t',
    't/05-unit-shortcuts-integrity.t',
    't/06-find-fatals.t',
    't/regression/00-issue1--illegal-div-zero.t'
);

notabs_ok($_) foreach @files;
done_testing;
