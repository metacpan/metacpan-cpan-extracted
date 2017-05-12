use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Path/ScanINC.pm',
    't/00-compile/lib_Path_ScanINC_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01_construction.t',
    't/02_immutable.t',
    't/03_basic_scanfile.t',
    't/04_internals.t',
    't/lib/winfail.pm',
    't/mocksystem/liba/.keep',
    't/mocksystem/liba/example1/.keep',
    't/mocksystem/libb/.keep',
    't/mocksystem/libc/.keep',
    't/mocksystem/libc/example2/.keep',
    't/mocksystem/libd/.keep'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
