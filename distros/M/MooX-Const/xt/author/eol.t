use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/MooX/Const.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/10-has.t',
    't/20-moo.t',
    't/21-moox-typetiny.t',
    't/22-moo-coerce.t',
    't/23-moo-mungehas.t',
    't/30-strict.t',
    't/31-strict.t',
    't/40-moose.t',
    't/lib/MooTest.pm',
    't/lib/MooTest/MungeHas.pm',
    't/lib/MooTest/Strict.pm',
    't/lib/MooseTest.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
