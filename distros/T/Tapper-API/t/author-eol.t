
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/tapper-rest-api',
    'bin/tapper-rest-api-daemon',
    'lib/Mojolicious/Plugin/TapperConfig.pm',
    'lib/Tapper/API.pm',
    'lib/Tapper/API/Plugin/API.pm',
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

eol_unix_ok($_, { trailing_whitespace => 0 }) foreach @files;
done_testing;
