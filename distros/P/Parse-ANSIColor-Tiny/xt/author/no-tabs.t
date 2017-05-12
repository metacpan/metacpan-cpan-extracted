use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Parse/ANSIColor/Tiny.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/chart.t',
    't/chart_256.t',
    't/colors.t',
    't/encoding.t',
    't/exports.t',
    't/identify.t',
    't/normalize.t',
    't/parse.t',
    't/process.t',
    't/process_reverse.t',
    't/remove_escapes.t',
    't/synopsis.t',
    't/term-ansicolor.t'
);

notabs_ok($_) foreach @files;
done_testing;
