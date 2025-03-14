
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
    'lib/Tapper/Remote.pm',
    'lib/Tapper/Remote/Config.pm',
    'lib/Tapper/Remote/Net.pm',
    't/00-load.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/files/config.yml',
    't/release-pod-coverage.t',
    't/tapper-remote-config-prc.t',
    't/tapper-remote-config.t',
    't/tapper-remote-net.t'
);

notabs_ok($_) foreach @files;
done_testing;
