
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Object/RateLimiter.pm',
    'lib/Role/Object/RateLimiter.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/json.t',
    't/limit.t',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t',
    't/release-pod-linkcheck.t',
    't/release-synopsis.t',
    't/release-unused-vars.t',
    't/role.t',
    't/storable.t'
);

notabs_ok($_) foreach @files;
done_testing;
