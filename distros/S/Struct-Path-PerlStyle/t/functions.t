#!perl -T

use strict;
use warnings;

use Struct::Path::PerlStyle qw(str2path);
use Test::More tests => 6;

my $args = [
    [[0],[1]], # path should be passed as first arg
    [\"a",\"b"], # data refs array as second
];

ok(
    str2path('[0](back)')->[1]->($args->[0], $args->[1]),
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

my $spath = str2path('[0](back 2)');
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
    str2path('[0](back 3)')->[1]->($args->[0], $args->[1]),
    undef,
    "back() should return undef when unable to step back"
);

