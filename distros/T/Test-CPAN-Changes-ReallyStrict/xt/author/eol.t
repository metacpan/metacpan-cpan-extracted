use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Test/CPAN/Changes/ReallyStrict.pm',
    'lib/Test/CPAN/Changes/ReallyStrict/Object.pm',
    't/00-compile/lib_Test_CPAN_Changes_ReallyStrict_Object_pm.t',
    't/00-compile/lib_Test_CPAN_Changes_ReallyStrict_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01_basic_mock.t',
    't/01_basic_mock_oo.t',
    't/02_basic_mock_inprogress.t',
    't/02_basic_mock_inprogress_oo.t',
    't/03_keep_comparing_keeps_comparing.t',
    't/03_keep_comparing_keeps_comparing_oo.t',
    't/04_next_token.t',
    't/04_next_token_oo.t',
    't/99_changes_strict.t',
    't/99_changes_strict_oo.t',
    't/lib/Requires/CCAPI.pm',
    't/lib/mocktest.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
