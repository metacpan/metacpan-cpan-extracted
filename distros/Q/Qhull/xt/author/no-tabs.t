use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Qhull.pm',
    'lib/Qhull/Options.pm',
    'lib/Qhull/PP.pm',
    'lib/Qhull/Util.pm',
    'lib/Qhull/Util/Options.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/Util/parse_output.t',
    't/data/Util/parse_output/extrema.json',
    't/data/Util/parse_output/extrema.txt',
    't/data/Util/parse_output/facets2D.json',
    't/data/Util/parse_output/facets2D.txt',
    't/data/Util/parse_output/sizes.json',
    't/data/Util/parse_output/sizes.txt',
    't/data/Util/parse_output/vertex2D.json',
    't/data/Util/parse_output/vertex2D.txt',
    't/data/qhull/qhull.in',
    't/data/qhull/qhull.out',
    't/qhull.t'
);

notabs_ok($_) foreach @files;
done_testing;
