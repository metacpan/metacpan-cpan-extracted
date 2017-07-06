#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 4;

use Struct::Path qw(spath);

use lib "t";
use _common qw($s_mixed t_dump);

my @r;

@r = spath($s_mixed, [ {keys => ['c']} ]);
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

@r = spath($s_mixed, [ {keys => ['a']} ], assign => "new a value");
is_deeply(
    $s_mixed,
    {
        a => "new a value",
        b => {ba => 'vba',bb => 'vbb'},
        c => 'vc_replaced'
    },
    "replace {a} value via option 'assign'"
) or diag t_dump $s_mixed;

@r = spath($s_mixed, [ {keys => ['b']} ], assign => undef);
is_deeply(
    $s_mixed,
    {
        a => "new a value",
        b => undef,
        c => 'vc_replaced'
    },
    "replace {b} value by undef via option 'assign'"
) or diag t_dump $s_mixed;

@r = spath($s_mixed, [ {keys => ['b']} ], assign => 'blah-blah', delete => 1);
is_deeply(
    $s_mixed,
    {
        a => "new a value",
        c => 'vc_replaced'
    },
    "replace {b} value via option 'assign' and delete at the same time -- key must be removed"
) or diag t_dump $s_mixed;

