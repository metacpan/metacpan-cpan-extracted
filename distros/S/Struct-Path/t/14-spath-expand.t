#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More tests => 8;

use Struct::Path qw(spath);

use Storable qw(dclone);

use lib "t";
use _common qw($s_mixed);

my (@r, $tmp);

$tmp = dclone($s_mixed);
eval { @r = spath($tmp, [ {keys => ['b']},[0] ], expand => 1, strict => 1) };
like($@, qr/^ARRAY expected on step #1, got HASH/);

$tmp = dclone($s_mixed);
eval { @r = spath($tmp, [ {keys => ['a']},[1],{keys => ['a1a']} ], expand => 1, strict => 1) };
like($@, qr/^HASH expected on step #2, got ARRAY/);

$tmp = 'Will be overwritten';
@r = spath(\$tmp, [ {keys => ['a']},[3] ], expand => 1);
is_deeply(
    $tmp,
    {a => [undef,undef,undef,undef]},
    "expand undef to {a}[3]"
);

### ARRAYS ###

$tmp = dclone($s_mixed);
@r = spath($tmp, [ {keys => ['a']},[3] ], expand => 1);
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
@r = spath($tmp, [ {keys => ['a']},[3],[1] ], expand => 1);
is_deeply(
    $tmp,
    {
        a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0','a1'],undef,[undef,undef]],
        b => {ba => 'vba',bb => 'vbb'},
        c => 'vc'
    },
    "create {a}[3][1]"
);

### HASHES ###

$tmp = dclone($s_mixed);
@r = spath($tmp, [ {keys => ['d']} ], expand => 1);
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
@r = spath($tmp, [ {keys => ['d']},{keys => ['da', 'db']} ], expand => 1);
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
@r = spath($tmp, [ {keys => ['a']},[0,3],{keys => ['ana', 'anb']},[1] ], expand => 1);
is_deeply(
    $tmp,
    {a => [{ana => [undef,undef],anb => [undef,undef]},undef,undef,{ana => [undef,undef],anb => [undef,undef]}]},
    "expand {a}[0,3]{ana,anb}[1]"
);
