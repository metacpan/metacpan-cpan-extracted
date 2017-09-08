use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

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

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
