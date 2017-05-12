
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
    'lib/Tapper/Cmd.pm',
    'lib/Tapper/Cmd/Cobbler.pm',
    'lib/Tapper/Cmd/DbDeploy.pm',
    'lib/Tapper/Cmd/Host.pm',
    'lib/Tapper/Cmd/Init.pm',
    'lib/Tapper/Cmd/Notification.pm',
    'lib/Tapper/Cmd/Precondition.pm',
    'lib/Tapper/Cmd/Queue.pm',
    'lib/Tapper/Cmd/Requested.pm',
    'lib/Tapper/Cmd/Scenario.pm',
    'lib/Tapper/Cmd/Testplan.pm',
    'lib/Tapper/Cmd/Testrun.pm',
    'lib/Tapper/Cmd/User.pm',
    't/00-load.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/fixtures/reportsdb/report.yml',
    't/fixtures/testrundb/testrun_with_preconditions.yml',
    't/fixtures/testrundb/testruns_with_scheduling.yml',
    't/includes/vendors',
    't/misc_files/scenario.sc',
    't/misc_files/single.sc',
    't/misc_files/testplan.mpc',
    't/misc_files/testplan_with_scenario.mpc',
    't/misc_files/testplan_with_substitutes.tp',
    't/misc_files/testrun.mpc',
    't/tapper-cmd-cobbler.t',
    't/tapper-cmd-host.t',
    't/tapper-cmd-notify.t',
    't/tapper-cmd-precondition.t',
    't/tapper-cmd-queue.t',
    't/tapper-cmd-requested.t',
    't/tapper-cmd-scenario.t',
    't/tapper-cmd-testplan.t',
    't/tapper-cmd-testrun.t',
    't/tapper-cmd-user.t'
);

eol_unix_ok($_, { trailing_whitespace => 0 }) foreach @files;
done_testing;
