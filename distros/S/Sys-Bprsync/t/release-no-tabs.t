
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
    'bin/bprsync.pl',
    'lib/Sys/Bprsync.pm',
    'lib/Sys/Bprsync/Cmd.pm',
    'lib/Sys/Bprsync/Cmd/Command.pm',
    'lib/Sys/Bprsync/Cmd/Command/configcheck.pm',
    'lib/Sys/Bprsync/Cmd/Command/run.pm',
    'lib/Sys/Bprsync/Job.pm',
    'lib/Sys/Bprsync/Worker.pm'
);

notabs_ok($_) foreach @files;
done_testing;
