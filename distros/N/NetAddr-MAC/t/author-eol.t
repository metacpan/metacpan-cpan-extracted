
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print "1..0 # SKIP these tests are for testing by the author\n";
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/NetAddr/MAC.pm',
    't/00-load.t',
    't/130-utils-mac.t',
    't/131-utils-mac-properties.t',
    't/132-utils-mac-normals.t',
    't/140-new.t',
    't/150-misc-bad-formats-via-die.t',
    't/author-critic.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-no-breakpoints.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-spell.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/release-distmeta.t',
    't/release-kwalitee.t',
    't/release-unused-vars.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
