use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/MooX/NewDefaults.pm',
    't/00-compile/lib_MooX_NewDefaults_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-sanity.t',
    't/array.t',
    't/non-coderef.t',
    't/sugar.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
