
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.06

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Net/Async/Webservice/Common.pm',
    'lib/Net/Async/Webservice/Common/Exception.pm',
    'lib/Net/Async/Webservice/Common/SyncAgentWrapper.pm',
    'lib/Net/Async/Webservice/Common/Types.pm',
    'lib/Net/Async/Webservice/Common/WithConfigFile.pm',
    'lib/Net/Async/Webservice/Common/WithRequestWrapper.pm',
    'lib/Net/Async/Webservice/Common/WithUserAgent.pm'
);

notabs_ok($_) foreach @files;
done_testing;
