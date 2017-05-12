
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
    'bin/tapper-reports-receiver',
    'bin/tapper-reports-receiver-daemon',
    'lib/Tapper/Reports/Receiver.pm',
    'lib/Tapper/Reports/Receiver/Daemon.pm',
    'lib/Tapper/Reports/Receiver/Level2/Codespeed.pm',
    'lib/Tapper/Reports/Receiver/Util.pm',
    't/00-load.t',
    't/archive.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/datetime_stuff.t',
    't/files/report_owner_from_db',
    't/files/report_owner_in_header',
    't/fixtures/hardwaredb/systems.yml',
    't/fixtures/testrundb/report.yml',
    't/fixtures/testrundb/testrun_with_preconditions.yml',
    't/release-pod-coverage.t',
    't/tap-archive-2-codespeed.tap',
    't/tapper-reports-receiver-level2.t',
    't/tapper-reports-receiver.t',
    't/tapper.cfg'
);

eol_unix_ok($_, { trailing_whitespace => 0 }) foreach @files;
done_testing;
