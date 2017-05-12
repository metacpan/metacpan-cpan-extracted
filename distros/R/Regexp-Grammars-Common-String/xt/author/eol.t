use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Regexp/Grammars/Common/String.pm',
    't/00-compile/lib_Regexp_Grammars_Common_String_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01_consume.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
