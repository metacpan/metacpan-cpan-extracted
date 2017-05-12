
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.05

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/revobackup.pl',
    'lib/Sys/RevoBackup.pm',
    'lib/Sys/RevoBackup/Cmd.pm',
    'lib/Sys/RevoBackup/Cmd/Command.pm',
    'lib/Sys/RevoBackup/Cmd/Command/backupcheck.pm',
    'lib/Sys/RevoBackup/Cmd/Command/cleanup.pm',
    'lib/Sys/RevoBackup/Cmd/Command/configcheck.pm',
    'lib/Sys/RevoBackup/Cmd/Command/run.pm',
    'lib/Sys/RevoBackup/Job.pm',
    'lib/Sys/RevoBackup/Plugin.pm',
    'lib/Sys/RevoBackup/Plugin/Zabbix.pm',
    'lib/Sys/RevoBackup/Utils.pm',
    'lib/Sys/RevoBackup/Worker.pm'
);

notabs_ok($_) foreach @files;
done_testing;
