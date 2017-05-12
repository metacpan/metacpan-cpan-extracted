
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
    'lib/Net/Salesforce.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/author-no-tabs.t',
    't/basic.t',
    't/manifest.t',
    't/pod-coverage.t',
    't/pod.t',
    't/release-kwalitee.t',
    't/release-minimum-version.t'
);

notabs_ok($_) foreach @files;
done_testing;
