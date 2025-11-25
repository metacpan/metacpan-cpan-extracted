
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
    'lib/Perl/Critic/Policy/BuiltinFunctions/ProhibitForeach.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/20-policy.t',
    't/30-methods.t',
    't/author-distmeta.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-no-breakpoints.t',
    't/author-no-tabs.t',
    't/author-pod-no404s.t',
    't/author-pod-spell.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/release-kwalitee.t',
    't/release-pause-permissions.t',
    't/release-test-legal.t',
    't/release-unused-vars.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
