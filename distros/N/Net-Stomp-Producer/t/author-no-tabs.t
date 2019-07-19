
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
