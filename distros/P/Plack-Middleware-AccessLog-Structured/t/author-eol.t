
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
    'lib/Plack/Middleware/AccessLog/Structured.pm',
    't/00-compile.t',
    't/000-report-versions-tiny.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/lib/Plack/Middleware/AccessLog/StructuredTest.pm',
    't/plack.middleware.access-log.structured.t',
    't/release-cpan-changes.t',
    't/release-distmeta.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
