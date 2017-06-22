#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More tests => 10;

use Struct::Path qw(slist);

use Storable qw(freeze);
$Storable::canonical = 1;

use lib "t";
use _common qw($s_array $s_hash $s_mixed);

my (@list, $frozen);

$frozen = freeze($s_array);

@list = slist($s_array);
is_deeply(
    \@list,
    [
        [[0]], \3,
        [[1]], \1,
        [[2]], \5,
        [[3],[0]], \9,
        [[3],[1],[0]], \13,
        [[3],[2]], \7,
        [[4]], \11
    ],
    "List AoA struct"
);
ok(freeze($s_array) eq $frozen);

$frozen = freeze($s_hash);
@list = slist($s_hash);
is_deeply(
    \@list,
    [
        [{keys => ['a']}], \'av',
        [{keys => ['b']},{keys => ['ba']}], \'vba',
        [{keys => ['b']},{keys => ['vb']}], \'vbb',
        [{keys => ['c']}], \{}
    ],
    "List HoH struct"
);
ok(freeze($s_hash) eq $frozen);

$frozen = freeze($s_mixed);

@list = slist($s_mixed);
is_deeply(
    \@list,
    [
        [{keys => ['a']},[0],{keys => ['a2a']},{keys => ['a2aa']}], \0,
        [{keys => ['a']},[0],{keys => ['a2b']},{keys => ['a2ba']}], \undef,
        [{keys => ['a']},[0],{keys => ['a2c']},{keys => ['a2ca']}], \[],
        [{keys => ['a']},[1],[0]], \'a0',
        [{keys => ['a']},[1],[1]], \'a1',
        [{keys => ['b']},{keys => ['ba']}], \'vba',
        [{keys => ['b']},{keys => ['bb']}], \'vbb',
        [{keys => ['c']}], \'vc'
    ],
    "List for mixed struct"
);

@list = slist($s_mixed, depth => 0); # depth 0 == whole struct
is_deeply(
    \@list,
    [
        [], \{
                a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0','a1']],
                b => {ba => 'vba',bb => 'vbb'},
                c => 'vc'
             }
    ],
    "List mixed struct, depth 0"
);

@list = slist($s_mixed, depth => 1);
is_deeply(
    \@list,
    [
        [{keys => ['a']}], \[{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0','a1']],
        [{keys => ['b']}], \{ba => 'vba',bb => 'vbb'},
        [{keys => ['c']}], \'vc'
    ],
    "List mixed struct, depth 1"
);

@list = slist($s_mixed, depth => 3);
is_deeply(
    \@list,
    [
        [{keys => ['a']},[0],{keys => ['a2a']}], \{a2aa => 0},
        [{keys => ['a']},[0],{keys => ['a2b']}], \{a2ba => undef},
        [{keys => ['a']},[0],{keys => ['a2c']}], \{a2ca => []},
        [{keys => ['a']},[1],[0]], \'a0',
        [{keys => ['a']},[1],[1]], \'a1',
        [{keys => ['b']},{keys => ['ba']}], \'vba',
        [{keys => ['b']},{keys => ['bb']}], \'vbb',
        [{keys => ['c']}], \'vc'
    ],
    "List mixed struct, depth 3"
);

@list = slist($s_mixed, depth => 100);
is_deeply(
    \@list,
    [
        [{keys => ['a']},[0],{keys => ['a2a']},{keys => ['a2aa']}], \0,
        [{keys => ['a']},[0],{keys => ['a2b']},{keys => ['a2ba']}], \undef,
        [{keys => ['a']},[0],{keys => ['a2c']},{keys => ['a2ca']}], \[],
        [{keys => ['a']},[1],[0]], \'a0',
        [{keys => ['a']},[1],[1]], \'a1',
        [{keys => ['b']},{keys => ['ba']}], \'vba',
        [{keys => ['b']},{keys => ['bb']}], \'vbb',
        [{keys => ['c']}], \'vc'
    ],
    "List mixed struct, depth 100"
);

ok(freeze($s_mixed) eq $frozen);
