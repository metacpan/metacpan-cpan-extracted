
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.08

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/mon-spooler-api.cgi',
    'bin/mon-spooler-api.psgi',
    'bin/mon-spooler.cgi',
    'bin/mon-spooler.pl',
    'bin/mon-spooler.psgi',
    'lib/Monitoring/Spooler.pm',
    'lib/Monitoring/Spooler/Cmd.pm',
    'lib/Monitoring/Spooler/Cmd/Command.pm',
    'lib/Monitoring/Spooler/Cmd/Command/bootstrap.pm',
    'lib/Monitoring/Spooler/Cmd/Command/create.pm',
    'lib/Monitoring/Spooler/Cmd/Command/email.pm',
    'lib/Monitoring/Spooler/Cmd/Command/flush.pm',
    'lib/Monitoring/Spooler/Cmd/Command/list.pm',
    'lib/Monitoring/Spooler/Cmd/Command/phone.pm',
    'lib/Monitoring/Spooler/Cmd/Command/rm.pm',
    'lib/Monitoring/Spooler/Cmd/Command/text.pm',
    'lib/Monitoring/Spooler/Cmd/SendingCommand.pm',
    'lib/Monitoring/Spooler/DB.pm',
    'lib/Monitoring/Spooler/Transport.pm',
    'lib/Monitoring/Spooler/Transport/Pjsua.pm',
    'lib/Monitoring/Spooler/Transport/Sipgate.pm',
    'lib/Monitoring/Spooler/Transport/SmsSend.pm',
    'lib/Monitoring/Spooler/Transport/Smstrade.pm',
    'lib/Monitoring/Spooler/Web.pm',
    'lib/Monitoring/Spooler/Web/API.pm',
    'lib/Monitoring/Spooler/Web/Frontend.pm',
    't/release-eol.t',
    't/release-no-tabs.t',
    't/release-pod-syntax.t'
);

notabs_ok($_) foreach @files;
done_testing;
