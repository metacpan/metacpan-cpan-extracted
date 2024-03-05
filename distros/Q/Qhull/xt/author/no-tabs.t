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
    't/data/extrema.json',
    't/data/extrema.txt',
    't/data/facets2D.json',
    't/data/facets2D.txt',
    't/data/vertex2D.json',
    't/data/vertex2D.txt'
);

notabs_ok($_) foreach @files;
done_testing;
