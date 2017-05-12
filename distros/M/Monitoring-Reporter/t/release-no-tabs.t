
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
    'bin/mreporter-web.pl',
    'bin/mreporter-web.psgi',
    'bin/mreporter.pl',
    'lib/Monitoring/Reporter.pm',
    'lib/Monitoring/Reporter/Backend.pm',
    'lib/Monitoring/Reporter/Backend/NagiosLivestatus.pm',
    'lib/Monitoring/Reporter/Backend/ZabbixDBI.pm',
    'lib/Monitoring/Reporter/Cmd.pm',
    'lib/Monitoring/Reporter/Cmd/Command.pm',
    'lib/Monitoring/Reporter/Cmd/Command/actions.pm',
    'lib/Monitoring/Reporter/Cmd/Command/list.pm',
    'lib/Monitoring/Reporter/Web.pm',
    'lib/Monitoring/Reporter/Web/Plugin.pm',
    'lib/Monitoring/Reporter/Web/Plugin/Demo.pm',
    'lib/Monitoring/Reporter/Web/Plugin/History.pm',
    'lib/Monitoring/Reporter/Web/Plugin/List.pm',
    'lib/Monitoring/Reporter/Web/Plugin/Selftest.pm'
);

notabs_ok($_) foreach @files;
done_testing;
