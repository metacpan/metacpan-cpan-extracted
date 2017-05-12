
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Plack/Handler/Stomp.pm',
    'lib/Plack/Handler/Stomp/Exceptions.pm',
    'lib/Plack/Handler/Stomp/NoNetwork.pm',
    'lib/Plack/Handler/Stomp/PathInfoMunger.pm',
    'lib/Plack/Handler/Stomp/Types.pm',
    'lib/Test/Plack/Handler/Stomp.pm',
    'lib/Test/Plack/Handler/Stomp/FakeStomp.pm',
    't/basic.t',
    't/building_request.t',
    't/connect_global_headers.t',
    't/connect_local_headers.t',
    't/exceptions.t',
    't/lib/BrokerTestApp.pm',
    't/lib/MyTesting.pm',
    't/lib/RunTestApp.pm',
    't/lib/RunTestAppNoNet.pm',
    't/lib/TestApp.pm',
    't/logging.t',
    't/multi_server.t',
    't/nonetwork.t',
    't/path_info_subst.t',
    't/real_broker.t',
    't/request_subscription.t',
    't/response.t',
    't/subscription.t'
);

notabs_ok($_) foreach @files;
done_testing;
