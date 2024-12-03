
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
    'bin/tapper-reports-receiver',
    'bin/tapper-reports-receiver-daemon',
    'lib/Tapper/Reports/Receiver.pm',
    'lib/Tapper/Reports/Receiver/Daemon.pm',
    'lib/Tapper/Reports/Receiver/Level2/Codespeed.pm',
    'lib/Tapper/Reports/Receiver/Util.pm',
    't/00-compile.t',
    't/00-load.t',
    't/archive.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/datetime_stuff.t',
    't/files/report_owner_from_db',
    't/files/report_owner_in_header',
    't/fixtures/hardwaredb/systems.yml',
    't/fixtures/testrundb/report.yml',
    't/fixtures/testrundb/testrun_with_preconditions.yml',
    't/tap-archive-2-codespeed.tap',
    't/tapper-reports-receiver-level2.t',
    't/tapper-reports-receiver.t',
    't/tapper.cfg'
);

notabs_ok($_) foreach @files;
done_testing;
