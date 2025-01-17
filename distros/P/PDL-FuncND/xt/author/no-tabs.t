use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/PDL/FuncND.pm',
    't/00-compile.t',
    't/00-load.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-funcs/cauchyND.t',
    't/01-funcs/gaussND.t',
    't/01-funcs/lorentzND.t',
    't/01-funcs/mahalanobis.t',
    't/01-funcs/moffatND.t',
    't/02-api/center.t',
    't/02-api/single.t'
);

notabs_ok($_) foreach @files;
done_testing;
