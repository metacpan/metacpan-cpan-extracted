#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More tests => 10;

use Struct::Path qw(path);

use Storable qw(dclone);

use lib "t";
use _common qw($s_mixed t_dump);

my (@r, $tmp);

$tmp = dclone($s_mixed);
eval { @r = path($tmp, [ {K => ['b']},[0] ], expand => 1, strict => 1) };
like($@, qr/^ARRAY expected on step #1, got HASH/);

$tmp = dclone($s_mixed);
eval { @r = path($tmp, [ {K => ['a']},[1],{K => ['a1a']} ], expand => 1, strict => 1) };
like($@, qr/^HASH expected on step #2, got ARRAY/);

$tmp = 'Will be overwritten';
@r = path($tmp, [ {K => ['a']},[3] ], expand => 1);
is_deeply(
    $tmp,
    {a => [undef,undef,undef,undef]},
    "expand undef to {a}[3]"
);

### ARRAYS ###

$tmp = dclone($s_mixed);
@r = path($tmp, [ {K => ['a']},[3] ], expand => 1);
is_deeply(
    $tmp,
    {
        a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0','a1'],undef,undef],
        b => {ba => 'vba',bb => 'vbb'},
        c => 'vc'
    },
    "create {a}[3]"
);

$tmp = dclone($s_mixed);
@r = path($tmp, [ {K => ['a']},[3],[1] ], expand => 1);
is_deeply(
    $tmp,
    {
        a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0','a1'],undef,[undef,undef]],
        b => {ba => 'vba',bb => 'vbb'},
        c => 'vc'
    },
    "create {a}[3][1]"
);

$tmp = [];
@r = path($tmp, [ [-1] ], expand => 1);
is_deeply(
    $tmp,
    [undef],
    "expand by out of range negative index (-1)"
) or diag t_dump $tmp;

$tmp = [];
@r = path($tmp, [ [-3] ], expand => 1);
is_deeply(
    $tmp,
    [undef],
    "expand by out of range negative index (-3)"
) or diag t_dump $tmp;

### HASHES ###

$tmp = dclone($s_mixed);
@r = path($tmp, [ {K => ['d']} ], expand => 1);
is_deeply(
    $tmp,
    {
        a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0','a1']],
        b => {ba => 'vba',bb => 'vbb'},
        c => 'vc',d => undef
    },
    "create {d}"
);

$tmp = dclone($s_mixed);
@r = path($tmp, [ {K => ['d']},{K => ['da', 'db']} ], expand => 1);
is_deeply(
    $tmp,
    {
        a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0','a1']],
        b => {ba => 'vba',bb => 'vbb'},
        c => 'vc',
        d => {da => undef,db => undef}
    },
    "create {d}{da,db}"
);

### MIXED ###

$tmp = {};
@r = path($tmp, [ {K => ['a']},[0,3],{K => ['ana', 'anb']},[1] ], expand => 1);
is_deeply(
    $tmp,
    {a => [{ana => [undef,undef],anb => [undef,undef]},undef,undef,{ana => [undef,undef],anb => [undef,undef]}]},
    "expand {a}[0,3]{ana,anb}[1]"
);
