
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
    'bin/tapper-rest-api',
    'bin/tapper-rest-api-daemon',
    'lib/Mojolicious/Plugin/TapperConfig.pm',
    'lib/Tapper/API.pm',
    'lib/Tapper/API/Plugin/Integrationtest.pm',
    'lib/Tapper/API/Plugin/Unittest.pm',
    't/00-load.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/fixtures/testrundb/simple_testrun.yml',
    't/tapper-api.cfg',
    't/tapper-api.t',
    't/tapper-api.t.cfg'
);

notabs_ok($_) foreach @files;
done_testing;
