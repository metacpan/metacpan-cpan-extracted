
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.08

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Net/IANA/Services.pm',
    't/00-compile.t',
    't/000-report-versions-tiny.t',
    't/01_quick.t',
    't/02_examples.t'
);

notabs_ok($_) foreach @files;
done_testing;
