
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
    'bin/tapper',
    'bin/tapper-api',
    'bin/tapper-db-deploy',
    'lib/Tapper/CLI.pm',
    'lib/Tapper/CLI/API.pm',
    'lib/Tapper/CLI/API/Command/download.pm',
    'lib/Tapper/CLI/API/Command/upload.pm',
    'lib/Tapper/CLI/Base.pm',
    'lib/Tapper/CLI/Cobbler.pm',
    'lib/Tapper/CLI/DbDeploy.pm',
    'lib/Tapper/CLI/DbDeploy/Command/init.pm',
    'lib/Tapper/CLI/DbDeploy/Command/makeschemadiffs.pm',
    'lib/Tapper/CLI/DbDeploy/Command/saveschema.pm',
    'lib/Tapper/CLI/DbDeploy/Command/upgrade.pm',
    'lib/Tapper/CLI/Host.pm',
    'lib/Tapper/CLI/HostFeature.pm',
    'lib/Tapper/CLI/Init.pm',
    'lib/Tapper/CLI/Notification.pm',
    'lib/Tapper/CLI/Precondition.pm',
    'lib/Tapper/CLI/Queue.pm',
    'lib/Tapper/CLI/Scenario.pm',
    'lib/Tapper/CLI/Schema.pm',
    'lib/Tapper/CLI/Testplan.pm',
    'lib/Tapper/CLI/Testrun.pm',
    'lib/Tapper/CLI/User.pm',
    'lib/Tapper/CLI/Utils.pm',
    't/00-load.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/dummy-attachment.txt',
    't/files/include/standard.inc',
    't/files/interdep.sc',
    't/files/interdep_macro.sc',
    't/files/kernel_boot.mpc',
    't/files/macro.tt',
    't/files/notification.yml',
    't/files/notification_updated.yml',
    't/files/testplan/osrc/athlon/kernel.mpc',
    't/files/testplan/osrc/includes',
    't/fixtures/hardwaredb/systems.yml',
    't/fixtures/reportsdb/report.yml',
    't/fixtures/testrundb/testrun_with_preconditions.yml',
    't/fixtures/testrundb/testruns_with_scheduling.yml',
    't/tapper-cli-host.t',
    't/tapper-cli-hostfeature.t',
    't/tapper-cli-notification.t',
    't/tapper-cli-precondition.t',
    't/tapper-cli-queue.t',
    't/tapper-cli-scenario.t',
    't/tapper-cli-testplan.t',
    't/tapper-cli-testrun-small.t',
    't/tapper-cli-testrun.t',
    't/tapper-cli-utils.t'
);

eol_unix_ok($_, { trailing_whitespace => 0 }) foreach @files;
done_testing;
