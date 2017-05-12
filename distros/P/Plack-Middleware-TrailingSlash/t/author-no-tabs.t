
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
    'lib/Plack/Middleware/TrailingSlash.pm',
    't/01_init.t',
    't/02_basic.t',
    't/03_get_only.t',
    't/04_params.t',
    't/80_critic.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/release-check-changes.t',
    't/release-kwalitee.t'
);

notabs_ok($_) foreach @files;
done_testing;
