use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Parse/Keyword.pm',
    't/basic.t',
    't/closure.t',
    't/error.pl',
    't/error.t',
    't/fun/anon.t',
    't/fun/basic.t',
    't/fun/closure-proto.t',
    't/fun/compile-time.t',
    't/fun/defaults.t',
    't/fun/lib/Fun.pm',
    't/fun/name.t',
    't/fun/package.t',
    't/fun/recursion.t',
    't/fun/slurpy-syntax-errors.t',
    't/fun/slurpy.t',
    't/fun/state.t',
    't/keyword-name.t',
    't/lexical.t',
    't/lib/My/Parser.pm',
    't/peek.t',
    't/scope-inject.t',
    't/try/basic.t',
    't/try/context.t',
    't/try/finally.t',
    't/try/given_when.t',
    't/try/lib/Error1.pm',
    't/try/lib/Error2.pm',
    't/try/lib/Try.pm',
    't/try/syntax.t',
    't/try/when.t',
    't/unavailable.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
