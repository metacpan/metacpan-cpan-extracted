
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Net/Stomp/MooseHelpers.pm',
    'lib/Net/Stomp/MooseHelpers/CanConnect.pm',
    'lib/Net/Stomp/MooseHelpers/CanSubscribe.pm',
    'lib/Net/Stomp/MooseHelpers/Exceptions.pm',
    'lib/Net/Stomp/MooseHelpers/ReadTrace.pm',
    'lib/Net/Stomp/MooseHelpers/ReconnectOnFailure.pm',
    'lib/Net/Stomp/MooseHelpers/TraceOnly.pm',
    'lib/Net/Stomp/MooseHelpers/TraceStomp.pm',
    'lib/Net/Stomp/MooseHelpers/TracerRole.pm',
    'lib/Net/Stomp/MooseHelpers/Types.pm',
    't/connect.t',
    't/permissions.t',
    't/subscribe.t',
    't/tracing.t'
);

notabs_ok($_) foreach @files;
done_testing;
