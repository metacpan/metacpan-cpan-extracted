#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More tests => 10;

use Struct::Path qw(list_paths);

use Storable qw(freeze);
$Storable::canonical = 1;

use lib "t";
use _common qw($s_array $s_hash $s_mixed);

my (@list, $frozen);

$frozen = freeze($s_array);

@list = list_paths($s_array);
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
@list = list_paths($s_hash);
is_deeply(
    \@list,
    [
        [{K => ['a']}], \'av',
        [{K => ['b']},{K => ['ba']}], \'vba',
        [{K => ['b']},{K => ['vb']}], \'vbb',
        [{K => ['c']}], \{}
    ],
    "List HoH struct"
);
ok(freeze($s_hash) eq $frozen);

$frozen = freeze($s_mixed);

@list = list_paths($s_mixed);
is_deeply(
    \@list,
    [
        [{K => ['a']},[0],{K => ['a2a']},{K => ['a2aa']}], \0,
        [{K => ['a']},[0],{K => ['a2b']},{K => ['a2ba']}], \undef,
        [{K => ['a']},[0],{K => ['a2c']},{K => ['a2ca']}], \[],
        [{K => ['a']},[1],[0]], \'a0',
        [{K => ['a']},[1],[1]], \'a1',
        [{K => ['b']},{K => ['ba']}], \'vba',
        [{K => ['b']},{K => ['bb']}], \'vbb',
        [{K => ['c']}], \'vc'
    ],
    "List for mixed struct"
);

@list = list_paths($s_mixed, depth => 0); # depth 0 == whole struct
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

@list = list_paths($s_mixed, depth => 1);
is_deeply(
    \@list,
    [
        [{K => ['a']}], \[{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0','a1']],
        [{K => ['b']}], \{ba => 'vba',bb => 'vbb'},
        [{K => ['c']}], \'vc'
    ],
    "List mixed struct, depth 1"
);

@list = list_paths($s_mixed, depth => 3);
is_deeply(
    \@list,
    [
        [{K => ['a']},[0],{K => ['a2a']}], \{a2aa => 0},
        [{K => ['a']},[0],{K => ['a2b']}], \{a2ba => undef},
        [{K => ['a']},[0],{K => ['a2c']}], \{a2ca => []},
        [{K => ['a']},[1],[0]], \'a0',
        [{K => ['a']},[1],[1]], \'a1',
        [{K => ['b']},{K => ['ba']}], \'vba',
        [{K => ['b']},{K => ['bb']}], \'vbb',
        [{K => ['c']}], \'vc'
    ],
    "List mixed struct, depth 3"
);

@list = list_paths($s_mixed, depth => 100);
is_deeply(
    \@list,
    [
        [{K => ['a']},[0],{K => ['a2a']},{K => ['a2aa']}], \0,
        [{K => ['a']},[0],{K => ['a2b']},{K => ['a2ba']}], \undef,
        [{K => ['a']},[0],{K => ['a2c']},{K => ['a2ca']}], \[],
        [{K => ['a']},[1],[0]], \'a0',
        [{K => ['a']},[1],[1]], \'a1',
        [{K => ['b']},{K => ['ba']}], \'vba',
        [{K => ['b']},{K => ['bb']}], \'vbb',
        [{K => ['c']}], \'vc'
    ],
    "List mixed struct, depth 100"
);

ok(freeze($s_mixed) eq $frozen);
