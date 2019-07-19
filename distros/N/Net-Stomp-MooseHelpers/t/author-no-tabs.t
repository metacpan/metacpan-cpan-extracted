
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
