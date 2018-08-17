#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 10;

use Struct::Path qw(path);

use lib "t";
use _common qw($s_mixed t_dump);

my ($got, @r);

$got = undef;
path($got, [], assign => 'test');
is_deeply($got, 'test', "Replace entire thing (scalar) via assign opt") ||
    diag t_dump $got;

$got = [ 'original' ];
path($got, [], assign => 'test');
is_deeply($got, 'test', "Replace entire thing (array) via assign opt") ||
    diag t_dump $got;

$got = [];
path($got, [[-3]], assign => 'test');
is_deeply($got, [], "Out of range, nostrict, noexpand") ||
    diag t_dump $got;

$got = [];
path($got, [[-3]], assign => 'test', expand => 1);
is_deeply($got, ['test'], "Out of range, nostrict, expand") ||
    diag t_dump $got;

$got = 42;
@r = path($got, []);
${$r[0]} = 'test';
is_deeply($got, 'test', "Replace entire thing (scalar) via output") ||
    diag t_dump $got;

$got = [0, 1];
@r = path($got, []);
${$r[0]} = 'test';
is_deeply($got, 'test', "Replace entire thing (array) via output") ||
    diag t_dump $got;

@r = path($s_mixed, [ {K => ['c']} ]);
${$r[0]} = "vc_replaced";
is_deeply(
    $s_mixed,
    {
        a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0','a1']],
        b => {ba => 'vba',bb => 'vbb'},
        c => 'vc_replaced'
    },
    "replace {c} value via returned reference"
) or diag t_dump $s_mixed;

@r = path($s_mixed, [ {K => ['a']} ], assign => "new a value");
is_deeply(
    $s_mixed,
    {
        a => "new a value",
        b => {ba => 'vba',bb => 'vbb'},
        c => 'vc_replaced'
    },
    "replace {a} value via option 'assign'"
) or diag t_dump $s_mixed;

@r = path($s_mixed, [ {K => ['b']} ], assign => undef);
is_deeply(
    $s_mixed,
    {
        a => "new a value",
        b => undef,
        c => 'vc_replaced'
    },
    "replace {b} value by undef via option 'assign'"
) or diag t_dump $s_mixed;

@r = path($s_mixed, [ {K => ['b']} ], assign => 'blah-blah', delete => 1);
is_deeply(
    $s_mixed,
    {
        a => "new a value",
        c => 'vc_replaced'
    },
    "replace {b} value via option 'assign' and delete at the same time -- key must be removed"
) or diag t_dump $s_mixed;

