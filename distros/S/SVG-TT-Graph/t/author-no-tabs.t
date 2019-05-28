
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
    'lib/SVG/TT/Graph.pm',
    'lib/SVG/TT/Graph/Bar.pm',
    'lib/SVG/TT/Graph/BarHorizontal.pm',
    'lib/SVG/TT/Graph/BarLine.pm',
    'lib/SVG/TT/Graph/Bubble.pm',
    'lib/SVG/TT/Graph/HeatMap.pm',
    'lib/SVG/TT/Graph/Line.pm',
    'lib/SVG/TT/Graph/Pie.pm',
    'lib/SVG/TT/Graph/TimeSeries.pm',
    'lib/SVG/TT/Graph/XY.pm',
    't/01_main.t',
    't/02_basic.t',
    't/03_methods.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t'
);

notabs_ok($_) foreach @files;
done_testing;
