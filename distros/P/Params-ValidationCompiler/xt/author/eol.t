use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Params/ValidationCompiler.pm',
    'lib/Params/ValidationCompiler/Compiler.pm',
    'lib/Params/ValidationCompiler/Exceptions.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/default.t',
    't/exceptions.t',
    't/moose.t',
    't/name-fails.t',
    't/name.t',
    't/named/args-check.t',
    't/named/const-hash.t',
    't/named/locked-hash.t',
    't/named/required.t',
    't/named/return-object.t',
    't/named/slurpy.t',
    't/pairs-to-value-list.t',
    't/positional/default.t',
    't/positional/required.t',
    't/positional/slurpy.t',
    't/self-check.t',
    't/source_for.t',
    't/specio.t',
    't/type-tiny.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
