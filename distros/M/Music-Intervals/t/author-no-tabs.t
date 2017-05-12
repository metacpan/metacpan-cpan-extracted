
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Music/Intervals.pm',
    'lib/Music/Intervals/Numeric.pm',
    'lib/Music/Intervals/Ratio.pm',
    'lib/Music/Intervals/Ratios.pm',
    't/00-compile.t',
    't/00-load.t',
    't/01-methods.t',
    't/02-numeric-methods.t',
    't/author-no-tabs.t',
    't/author-pod-spell.t',
    't/release-pod-syntax.t'
);

notabs_ok($_) foreach @files;
done_testing;
