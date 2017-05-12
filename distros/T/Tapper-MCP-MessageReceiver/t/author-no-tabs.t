
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
    'bin/tapper-mcp-messagereceiver',
    'bin/tapper-mcp-messagereceiver-daemon',
    'lib/Tapper/MCP/MessageReceiver.pm',
    't/00-load.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/fixtures/testrundb/testrun_empty.yml',
    't/release-pod-coverage.t',
    't/tapper-mcp-messagereceiver.t'
);

notabs_ok($_) foreach @files;
done_testing;
