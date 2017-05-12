#!perl

use 5.010;
use strict;
use warnings;
use Parse::VarName qw(split_varname_words);
use Test::More 0.98;

my @tests = (
    ['foo', [qw/foo/]],
    ['Foo', [qw/Foo/]],
    ['FOO', [qw/FOO/]],
    ['mTime', [qw/m Time/]],
    ['fooBar', [qw/foo Bar/]],
    ['fooBAR', [qw/foo BAR/]],
    ['FooBar', [qw/Foo Bar/]],
    ['FOObar', [qw/FOO bar/]],
    ['FOObAR', [qw/FOO b AR/]],
    ['foo1', [qw/foo 1/]],
    ['foo123', [qw/foo 123/]],
    ['foo1bar', [qw/foo 1 bar/]],
    ['_date', [qw/date/]],
    ['_date', [qw/_ date/], 1],
    ['__int', [qw/int/]],
    ['__int', [qw/__ int/], 1],
    ['create_date', [qw/create date/]],
    ['create_date', [qw/create _ date/], 1],
    ['foo::barBaz::qux0', [qw/foo bar Baz qux 0/]],
    ['foo::barBaz::qux0', [qw/foo :: bar Baz :: qux 0/], 1],
);

for my $t (@tests) {
    my $res = split_varname_words(varname=>$t->[0], include_sep=>$t->[2]);
    is_deeply($res, $t->[1], $t->[0])
        or diag explain $res;
}

DONE_TESTING:
done_testing();
