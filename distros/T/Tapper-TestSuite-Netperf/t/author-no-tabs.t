
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
    'bin/tapper-testsuite-netperf-client',
    'bin/tapper-testsuite-netperf-server',
    'lib/Tapper/TestSuite/Netperf.pm',
    'lib/Tapper/TestSuite/Netperf/Client.pm',
    'lib/Tapper/TestSuite/Netperf/Server.pm',
    't/00-compile.t',
    't/00-load.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/tapper-testsuite-netperf.t'
);

notabs_ok($_) foreach @files;
done_testing;
