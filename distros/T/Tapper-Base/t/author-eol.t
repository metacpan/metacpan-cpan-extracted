
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
    'lib/Tapper/Base.pm',
    't/00-compile.t',
    't/00-load.t',
    't/author-eol.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/misc_files/sleep.sh',
    't/tapper-base.t'
);

eol_unix_ok($_, { trailing_whitespace => 0 }) foreach @files;
done_testing;
