
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/String/Diff.pm',
    't/00-compile.t',
    't/00_compile-pp.t',
    't/00_compile.t',
    't/01_export-pp.t',
    't/01_export.t',
    't/02_diff_fully-pp.t',
    't/02_diff_fully.t',
    't/03_diff-pp.t',
    't/03_diff.t',
    't/04_diff_merge-pp.t',
    't/04_diff_merge.t',
    't/05_diff_regexp-pp.t',
    't/05_diff_regexp.t',
    't/06_escape.t',
    't/author-eol.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t'
);

eol_unix_ok($_, { trailing_whitespace => 0 }) foreach @files;
done_testing;
