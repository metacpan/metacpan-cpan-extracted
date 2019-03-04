#!perl -T

use strict;
use warnings;

use Struct::Path::PerlStyle qw(str2path);
use Test::More tests => 8;

my $args = [
    [[0],[1]], # path should be passed as first arg
    [\"a",\"b"], # data refs array as second
];

ok(
    str2path('[0](BACK)')->[1]->($args->[0], $args->[1]),
    "Step back must return 1"
);
is_deeply(
    $args,
    [[[0]], [\"a"]],
    "One step back"
);

$args = [
    [[0],[1]],
    [\"a",\"b"],
];

my $spath = str2path('[0](back 2)');  # lower-case alias testes also
ok(
    $spath->[1]->($args->[0], $args->[1]),
    "Step back must return 1"
);

is_deeply(
    $args,
    [[], []],
    "Two steps back"
);

$args = [
    [[0],[1]],
    [\"a",\"b"],
];

$spath->[1]->($args->[0], $args->[1]);
is_deeply(
    $args,
    [[], []],
    "Step back hook must be reusable"
);

$args = [
    [[0],[1]],
    [\"a",\"b"],
];

is(
    str2path('[0](BACK 3)')->[1]->($args->[0], $args->[1]),
    undef,
    "BACK() should return undef when unable to step back"
);

is(
    str2path('[0](BACK "text")')->[1]->($args->[0], $args->[1]),
    undef,
    "BACK() should return undef when not an int passed"
);

is(
    str2path('[0](BACK 0)')->[1]->($args->[0], $args->[1]),
    1,
    "BACK() should do nothing when zero passed for step amount"
);

