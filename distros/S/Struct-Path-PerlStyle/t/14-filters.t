#!perl -T

use strict;
use warnings;
use Struct::Path::PerlStyle qw(ps_parse);
use Test::More tests => 24;

eval { ps_parse('(<<') };
like($@, qr/^Unsupported thing '\(<<' in the path/, "Unclosed parenthesis");

eval { ps_parse('(<<}') };
like($@, qr/^Unsupported thing '\(<<' in the path/, "Unmatched brackets");

eval { ps_parse('[0](=>)[-2]') };
like($@, qr/^Unsupported operator '=>' specified/, "Unsupported operator");

eval { ps_parse('[0](<<(<<))[-2]') };
like($@, qr/^Unsupported thing '\(<<\)' as operator argument/, "Unsupported arg type");

eval { ps_parse('[0](<<<<)[-2]') };
like($@, qr/^Unsupported thing '<<' as operator argument/, "Unsupported arg type");

# args passed to callback by Struct::Path (sample)
my $args = [
    [[0],[1]], # path passed as first arg
    ["a","b"], # data refs array as second
];

ok(
    ps_parse('[0](<<)')->[1]->($args->[0], $args->[1]),
    "Step back must returns 1"
);

is_deeply(
    $args,
    [[[0]], ["a"]],
    "One step back"
);

$args = [
    [[0],[1]],
    ["a","b"],
];

my $spath = ps_parse('[0](<<2)');
ok(
    $spath->[1]->($args->[0], $args->[1]),
    "Step back must returns 1"
);

is_deeply(
    $args,
    [[], []],
    "Two steps back"
);

$args = [
    [[0],[1]],
    ["a","b"],
];

$spath->[1]->($args->[0], $args->[1]); # use this closure again
is_deeply(
    $args,
    [[], []],
    "Step back: closure must be reusable (keep arg untouched)"
);

$args = [
    [[0],[1]],
    ["a","b"],
];

eval { ps_parse('[0](<<3)')->[1]->($args->[0], $args->[1]) };
like(
    $@, qr/^Can't step back \(root of the structure\)/,
    "Must fail if backs steps more than current path length"
);

### regexp match

$args = [
    [[0],[1]],
    [\"foo",\"bar"],
];

eval { ps_parse("[0][1](=~ 'foo' 'bar')")->[2]->($args->[0], $args->[1]) };
like($@, qr/^Only one arg accepted by '=~'/, "As is");

ok(
    ps_parse("[0][1](=~ 'ar')")->[2]->($args->[0], $args->[1]),
    "eq must return true value here"
);

ok(
    ! ps_parse("[0][1](=~ '^ar')")->[2]->($args->[0], $args->[1]),
    "eq must return false value here"
);

$args = [ [[1]], [\undef] ];

ok(
    ps_parse("(not =~ 'b')")->[0]->($args->[0], $args->[1]),
    "eq must correctly handle undefs (doesn't croak)"
);

### eq

$args = [
    [[0],[1]],
    [\"a",\"b"],
];

eval { ps_parse("[0][1](eq 'b' 'c')")->[2]->($args->[0], $args->[1]) };
like($@, qr/^Only one arg accepted by 'eq'/, "As is");

ok(
    ps_parse("[0][1](eq 'b')")->[2]->($args->[0], $args->[1]),
    "eq must return true value here"
);

ok(
    ps_parse('[0][1](eq "b")')->[2]->($args->[0], $args->[1]),
    "eq must return true value here"
);

ok(
    ! ps_parse("[0][1](eq 'a')")->[2]->($args->[0], $args->[1]),
    "eq must return false value here"
);

$args = [ [[1]], [\undef] ];

ok(
    ps_parse("(not eq 'b')")->[0]->($args->[0], $args->[1]),
    "eq must correctly handle undefs"
);

### defined

ok(
    ! ps_parse('(defined)')->[0]->($args->[0], $args->[1]),
    "'defined' must return false value"
);

ok(
    ps_parse("(not defined)")->[0]->($args->[0], $args->[1]),
    "negate defined's false value"
);

ok(
    ps_parse("(! defined)")->[0]->($args->[0], $args->[1]),
    "negate defined's false value"
);

ok(
    ps_parse("(!defined)")->[0]->($args->[0], $args->[1]),
    "negate defined's false value"
);
