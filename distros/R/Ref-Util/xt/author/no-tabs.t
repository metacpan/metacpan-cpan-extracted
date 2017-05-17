use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Ref/Util.pm',
    'lib/Ref/Util/PP.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/all-permutations.t',
    't/arrayref.t',
    't/b-concise.t',
    't/dynamic.t',
    't/expr.t',
    't/functions.t',
    't/list.t',
    't/magic-readonly.t',
    't/magic.t',
    't/pureperl.t',
    't/toomany.t'
);

notabs_ok($_) foreach @files;
done_testing;
