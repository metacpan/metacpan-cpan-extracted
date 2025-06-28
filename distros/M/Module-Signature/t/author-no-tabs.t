
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Module/Signature.pm',
    'script/cpansign',
    't/0-signature.t',
    't/1-basic.t',
    't/2-cygwin.t',
    't/3-verify.t',
    't/author-critic.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/release-trailing-space.t',
    't/wrap.pl',
    't/wrapped-tests.bin'
);

notabs_ok($_) foreach @files;
done_testing;
