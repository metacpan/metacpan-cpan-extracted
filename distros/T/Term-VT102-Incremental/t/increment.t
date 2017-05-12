#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 7;

use Term::VT102::Incremental;

my $vti = Term::VT102::Incremental->new(rows => 1, cols => 6);

#$vti->get_increment();
$vti->process('f0o');

my @incr;

@incr = @{ $vti->get_increment() };
is($incr[0][2]{fg}, 7);
is($incr[1][2]{fg}, 7);
is($incr[2][2]{fg}, 7);

is($incr[0][2]{v}, 'f');
is($incr[1][2]{v}, '0');
is($incr[2][2]{v}, 'o');

$vti->process("\e[0;31m000\e[m");

@incr = @{ $vti->get_increment() };
is_deeply(
    [@incr[0..2]],
    [
        [0, 3, {v => '0', fg => 1}],
        [0, 4, {v => '0', fg => 1}],
        [0, 5, {v => '0', fg => 1}],
    ]
);

