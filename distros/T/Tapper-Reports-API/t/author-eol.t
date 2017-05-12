
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/tapper-reports-api',
    'bin/tapper-reports-api-daemon',
    'lib/Tapper/Reports/API.pm',
    'lib/Tapper/Reports/API/Daemon.pm',
    't/00-load.t',
    't/api.t',
    't/api_client_server.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/fixtures/testrundb/report.yml',
    't/perfmon_tests_planned.expected',
    't/perfmon_tests_planned.mas',
    't/perfmon_tests_planned.tt',
    't/tapper-reports-api-tt.t',
    't/test_payload.txt'
);

eol_unix_ok($_, { trailing_whitespace => 0 }) foreach @files;
done_testing;
