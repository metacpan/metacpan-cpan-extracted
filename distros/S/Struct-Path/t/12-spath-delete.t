#!perl -T
use 5.006;
use strict;
use warnings;
use Storable qw(dclone);
use Test::More tests => 29;

use Struct::Path qw(spath);

use lib "t";
use _common qw($s_array $s_mixed);

my (@r, $t);

# There is no right way to remove passed thing (set it to undef is no solution either)
eval { spath(\$t, [], delete => 1) };
like($@, qr/Unable to remove passed thing entirely \(empty path passed\) /,);

# delete single hash key
$t = dclone($s_mixed);
@r = spath($t, [ {keys => ['b']} ], delete => 1);
is_deeply(
    $t,
    {a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0','a1']],c => 'vc'},
    "delete {b}"
);

is_deeply(
    \@r,
    [\{ba => 'vba',bb => 'vbb'}],
    "delete {b}:: check returned value"
);

# delete single hash key, two steps
$t = dclone($s_mixed);
@r = spath($t, [ {keys => ['b']},{keys => ['ba']} ], delete => 1);
is_deeply(
    $t,
    {a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0','a1']],b => {bb => 'vbb'},c => 'vc'},
    "delete {b}{ba}"
);

is_deeply(
    \@r,
    [\'vba'],
    "delete {b}{ba}:: check returned value"
);

# delete all hash substruct
$t = dclone($s_mixed);
@r = spath($t, [ {keys => ['b']},{} ], delete => 1);
is_deeply(
    $t,
    {a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0','a1']],b => {},c => 'vc'},
    "delete {b}{}"
);

is_deeply(
    [ sort { ${$a} cmp ${$b} } @r ], # hash keys returned by hash seed (ie randomely, so, sort them)
    [\'vba',\'vbb'],
    "delete {b}{}:: check returned value"
);

# delete hash substruct with {} in the middle of the path
$t = dclone($s_mixed);
@r = spath($t, [ {keys => ['a']},[0],{},{keys => ['a2ba']} ], delete => 1);
is_deeply(
    $t,
    {a => [{a2a => {a2aa => 0},a2b => {},a2c => {a2ca => []}},['a0','a1']],b => {ba => 'vba',bb => 'vbb'},c => 'vc'},
    "delete {b}{}"
);

is_deeply(
    [ sort { ${$a} cmp ${$b} } @r ], # hash keys returned by hash seed (ie randomely, so, sort them)
    [\undef],
    "delete {b}{}:: check returned value"
);

# delete hash keys defined by regex
$t = dclone($s_mixed);
@r = spath($t, [ {regs => [qr/^a$/]},[0],{regs => [qr/2c$/,qr/2b$/]},{regs => [qr/^a2.a$/]} ], delete => 1);
is_deeply(
    $t,
    {a => [{a2a => {a2aa => 0},a2b => {},a2c => {}},['a0','a1']],b => {ba => 'vba',bb => 'vbb'},c => 'vc'},
    "delete hash keys by regex"
);

is_deeply(
    \@r,
    [\[],\undef],
    "check hash keys removal via regex"
);

# delete single array item from the beginning
$t = dclone($s_mixed);
@r = spath($t, [ {keys => ['a']},[0] ], delete => 1);
is_deeply(
    $t,
    {a => [['a0','a1']],b => {ba => 'vba',bb => 'vbb'},c => 'vc'},
    "delete {a}[0]"
);

is_deeply(
    \@r,
    [\{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}}],
    "delete {a}[0]:: check returned value"
);

# delete single array item from the end
$t = dclone($s_mixed);
@r = spath($t, [ {keys => ['a']},[1] ], delete => 1);
is_deeply(
    $t,
    {a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}}],b => {ba => 'vba',bb => 'vbb'},c => 'vc'},
    "delete {a}[1]"
);

is_deeply(
    \@r,
    [\['a0','a1']],
    "delete {a}[1]:: check returned value"
);

# delete single item from the middle of array
$t = dclone($s_array);
@r = spath($t, [ [3],[1] ], delete => 1);
is_deeply(
    $t,
    [3,1,5,[9,7],11],
    "delete [3][1]"
);

is_deeply(
    \@r,
    [\[13]],
    "delete [3][1]:: check returned value"
);

# delete several items from the middle of array to the out of range
$t = dclone($s_array);
@r = spath($t, [ [3],[1,2,3,4] ], delete => 1);
is_deeply(
    $t,
    [3,1,5,[9],11],
    "delete [3][1..4]"
);

is_deeply(
    \@r,
    [\[13],\7],
    "delete [3][1..4]:: check returned value"
);

# delete several array items, asc
$t = dclone($s_mixed);
@r = spath($t, [ {keys => ['a']},[0,1] ], delete => 1);
is_deeply(
    $t,
    {a => [],b => {ba => 'vba',bb => 'vbb'},c => 'vc'},
    "delete {a}[0,1]"
);

is_deeply(
    \@r,
    [\{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},\['a0','a1']],
    "delete {a}[0,1]:: check returned value"
);

# delete several array items, desc
$t = dclone($s_mixed);
@r = spath($t, [ {keys => ['a']},[1,0] ], delete => 1);
is_deeply(
    $t,
    {a => [],b => {ba => 'vba',bb => 'vbb'},c => 'vc'},
    "delete {a}[1,0]"
);

is_deeply(
    \@r,
    [\['a0','a1'],\{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}}],
    "delete {a}[1,0]:: check returned value"
);

# delete deep single array item
$t = dclone($s_mixed);
@r = spath($t, [ {keys => ['a']},[1],[1] ], delete => 1);
is_deeply(
    $t,
    {a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0']],b => {ba => 'vba',bb => 'vbb'},c => 'vc'},
    "delete {a}[1][1]"
);

is_deeply(
    \@r,
    [\'a1'],
    "delete {a}[1][1]:: check returned value"
);

# delete all array's items
$t = dclone($s_mixed);
@r = spath($t, [ {keys => ['a']},[1],[] ], delete => 1);
is_deeply(
    $t,
    {a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},[]],b => {ba => 'vba',bb => 'vbb'},c => 'vc'},
    "delete {a}[1][]"
);

is_deeply(
    \@r,
    [\'a0',\'a1'],
    "delete {a}[1][]:: check returned value"
);

# empty array in the middle of the path
$t = dclone($s_mixed);
@r = spath($t, [ {keys => ['a']},[],[1] ], delete => 1); # ok without 'strict'
is_deeply(
    $t,
    {a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0']],b => {ba => 'vba',bb => 'vbb'},c => 'vc'},
    "delete {a}[][1]"
);

is_deeply(
    \@r,
    [\'a1'],
    "delete {a}[][1]:: check returned value"
);

