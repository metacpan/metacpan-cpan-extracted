#!perl -T

use strict;
use warnings;
use Struct::Path::PerlStyle qw(str2path);
use Test::More tests => 24;

eval { str2path('(back') };
like($@, qr/^Unsupported thing '\(back' in the path/, "Unclosed parenthesis");

eval { str2path('(back}') };
like($@, qr/^Unsupported thing '\(back' in the path/, "Unmatched brackets");

eval { str2path('[0](=>)[-2]') };
like($@, qr/^Unsupported hook '=>', step #1 /, "Unsupported hook");

eval { str2path('[0](back(back))[-2]') };
like($@, qr/^Unsupported thing '\(back\)' as hook argument, step #1 /, "Unsupported arg type");

eval { str2path('[0](back back)[-2]') };
like($@, qr/^Unsupported thing 'back' as hook argument, step #1 /, "Unsupported arg type");

# args passed to callback by Struct::Path (sample)
my $args = [
    [[0],[1]], # path passed as first arg
    ["a","b"], # data refs array as second
];

ok(
    str2path('[0](back)')->[1]->($args->[0], $args->[1]),
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

my $spath = str2path('[0](back 2)');
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

eval { str2path('[0](back 3)')->[1]->($args->[0], $args->[1]) };
like(
    $@, qr/^Can't step back \(root of the structure\)/,
    "Must fail if backs steps more than current path length"
);

### regexp match

$args = [
    [[0],[1]],
    [\"foo",\"bar"],
];

eval { str2path("[0][1](=~ 'foo' 'bar')")->[2]->($args->[0], $args->[1]) };
like($@, qr/^Only one arg accepted by '=~'/, "As is");

ok(
    str2path("[0][1](=~ 'ar')")->[2]->($args->[0], $args->[1]),
    "eq must return true value here"
);

ok(
    ! str2path("[0][1](=~ '^ar')")->[2]->($args->[0], $args->[1]),
    "eq must return false value here"
);

$args = [ [[1]], [\undef] ];

ok(
    str2path("(not =~ 'b')")->[0]->($args->[0], $args->[1]),
    "eq must correctly handle undefs (doesn't croak)"
);

### eq

$args = [
    [[0],[1]],
    [\"a",\"b"],
];

eval { str2path("[0][1](eq 'b' 'c')")->[2]->($args->[0], $args->[1]) };
like($@, qr/^Only one arg accepted by 'eq'/, "As is");

ok(
    str2path("[0][1](eq 'b')")->[2]->($args->[0], $args->[1]),
    "eq must return true value here"
);

ok(
    str2path('[0][1](eq "b")')->[2]->($args->[0], $args->[1]),
    "eq must return true value here"
);

ok(
    ! str2path("[0][1](eq 'a')")->[2]->($args->[0], $args->[1]),
    "eq must return false value here"
);

$args = [ [[1]], [\undef] ];

ok(
    str2path("(not eq 'b')")->[0]->($args->[0], $args->[1]),
    "eq must correctly handle undefs"
);

### defined

ok(
    ! str2path('(defined)')->[0]->($args->[0], $args->[1]),
    "'defined' must return false value"
);

ok(
    str2path("(not defined)")->[0]->($args->[0], $args->[1]),
    "negate defined's false value"
);

ok(
    str2path("(! defined)")->[0]->($args->[0], $args->[1]),
    "negate defined's false value"
);

ok(
    str2path("(!defined)")->[0]->($args->[0], $args->[1]),
    "negate defined's false value"
);
