use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Path/Tiny/Rule.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t',
    't/pir/basic.t',
    't/pir/breadth-depth-files.t',
    't/pir/breadth-depth.t',
    't/pir/clone.t',
    't/pir/content.t',
    't/pir/error_handler.t',
    't/pir/fast.t',
    't/pir/helpers.t',
    't/pir/lib/PCNTest.pm',
    't/pir/lib/PIRTiny.pm',
    't/pir/logic.t',
    't/pir/min-max-depth.t',
    't/pir/names.t',
    't/pir/perl.t',
    't/pir/pir.t',
    't/pir/relative.t',
    't/pir/stat_tests.t',
    't/pir/stringify.t',
    't/pir/symlink.t',
    't/pir/unsorted.t',
    't/pir/vcs.t',
    't/pir/visitor.t',
    't/pir/x_tests.t'
);

notabs_ok($_) foreach @files;
done_testing;
