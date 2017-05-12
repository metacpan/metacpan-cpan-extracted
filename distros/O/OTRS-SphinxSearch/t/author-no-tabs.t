
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/OTRS/SphinxSearch.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/001.t',
    't/002.t',
    't/003.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/release-distmeta.t',
    't/release-pod-coverage.t',
    't/release-pod-syntax.t',
    't/release-test-version.t'
);

notabs_ok($_) foreach @files;
done_testing;
