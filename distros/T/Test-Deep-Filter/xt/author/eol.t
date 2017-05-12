use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Test/Deep/Filter.pm',
    'lib/Test/Deep/Filter/Object.pm',
    't/00-compile/lib_Test_Deep_Filter_Object_pm.t',
    't/00-compile/lib_Test_Deep_Filter_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-unhandled.t',
    't/03-child-matches.t',
    't/04-sub-matches.t',
    't/05-child-nonmatch.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
