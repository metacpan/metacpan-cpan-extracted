use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Test/Count.pm',
    'lib/Test/Count/Base.pm',
    'lib/Test/Count/FileMutator.pm',
    'lib/Test/Count/FileMutator/ByFileType/App.pm',
    'lib/Test/Count/FileMutator/ByFileType/Lib.pm',
    'lib/Test/Count/Filter.pm',
    'lib/Test/Count/Filter/ByFileType/App.pm',
    'lib/Test/Count/Lib.pm',
    'lib/Test/Count/Parser.pm',
    't/00-compile.t',
    't/01-parser.t',
    't/02-main.t',
    't/03-filter.t',
    't/04-modify-file-in-place.t',
    't/sample-data/test-scripts/01-parser-good.pl',
    't/sample-data/test-scripts/01-parser.pl',
    't/sample-data/test-scripts/arithmetics.pl',
    't/sample-data/test-scripts/basic.arc',
    't/sample-data/test-scripts/lib/MyMoreTests.pm',
    't/sample-data/test-scripts/with-include.pl',
    't/sample-data/test-scripts/with-indented-plan.pl'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
