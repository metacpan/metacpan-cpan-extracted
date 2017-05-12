
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
    'lib/Net/Stomp/Producer.pm',
    'lib/Net/Stomp/Producer/Exceptions.pm',
    'lib/Net/Stomp/Producer/Transactional.pm',
    't/buffered.t',
    't/lib/Stomp_LogCalls.pm',
    't/prevent-args-clobbering.t',
    't/produce.t',
    't/sending-failure.t'
);

notabs_ok($_) foreach @files;
done_testing;
