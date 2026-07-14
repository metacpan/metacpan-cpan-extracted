use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Number/Denominal.pm',
    't/00-compile.t',
    't/00-load.t',
    't/01-string.t',
    't/02-list.t',
    't/03-hashref.t',
    't/04-precision.t',
    't/05-unit-shortcuts-integrity.t',
    't/06-find-fatals.t',
    't/regression/00-issue1--illegal-div-zero.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
