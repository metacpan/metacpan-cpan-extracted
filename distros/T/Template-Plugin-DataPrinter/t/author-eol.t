
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
    'lib/Template/Plugin/DataPrinter.pm',
    't/00-compile.t',
    't/author-critic.t',
    't/author-distmeta.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/lib/Template/Plugin/DataPrinter/TestUtils.pm',
    't/rc_file.t',
    't/release-check-changes.t',
    't/release-cpan-changes.t',
    't/release-meta-json.t',
    't/tpdp.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
