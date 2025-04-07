use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Module/Runtime.pm',
    't/cmn.t',
    't/dependency.t',
    't/import_error.t',
    't/ivmn.t',
    't/ivms.t',
    't/lib/t/Break.pm',
    't/lib/t/Context.pm',
    't/lib/t/Eval.pm',
    't/lib/t/Hints.pm',
    't/lib/t/Nest0.pm',
    't/lib/t/Nest1.pm',
    't/lib/t/Simple.pm',
    't/mnf.t',
    't/rm.t',
    't/taint.t',
    't/um.t',
    't/upo.t',
    't/upo_overridden.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
