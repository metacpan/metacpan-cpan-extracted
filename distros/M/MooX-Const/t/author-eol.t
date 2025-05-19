
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
    'lib/MooX/Const.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/10-has.t',
    't/20-moo.t',
    't/21-moox-typetiny.t',
    't/22-moo-coerce.t',
    't/30-strict.t',
    't/31-strict.t',
    't/40-moose.t',
    't/author-clean-namespaces.t',
    't/author-critic.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-mixed-unicode-scripts.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-linkcheck.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/lib/MooTest.pm',
    't/lib/MooTest/Strict.pm',
    't/lib/MooseTest.pm',
    't/release-check-manifest.t',
    't/release-fixme.t',
    't/release-kwalitee.t',
    't/release-trailing-space.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
