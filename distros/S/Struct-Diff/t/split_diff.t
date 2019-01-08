#!perl -T

use strict;
use warnings FATAL => 'all';

use Storable qw(freeze);
use Struct::Diff qw(diff split_diff);
use Test::More tests => 19;

local $Storable::canonical = 1; # to have equal snapshots for equal by data hashes

my ($x, $y, $d, $frozen_d, $s);

### garbage ###
$s = split_diff({garbage_as_a_status => 'garbage'});
is_deeply($s, {}, "diff: {garbage_as_a_status => 'garbage'}");

### primitives ###
$s = split_diff(diff(0, 0));
is_deeply($s, {a => 0,b => 0}, "0 vs 0");

$s = split_diff(diff(0, 1));
is_deeply($s, {a => 0,b => 1}, "0 vs 1");

### arrays ###
is_deeply(
    split_diff(diff([], [0])),
    {a => [], b => [0]},
    'Old empty array should be preserved by split_diff()'
);

is_deeply(
    split_diff(diff([0], [])),
    {a => [0], b => []},
    'New empty array should be preserved by split_diff()'
);


$d = diff([ 0 ], [ 0, 1 ]);

$s = split_diff($d);
is_deeply($s, {a => [0],b => [0,1]}, "[0] vs [0,1]");

$s = split_diff(diff([ 0, 1 ], [ 0 ]));
is_deeply($s, {a => [0,1],b => [0]}, "[0,1] vs [0]");

my $sub_array = [ 0, [ 11, 12 ], 2 ];
$x = [ 0, [[ 100 ]], [ 20, 'a' ], $sub_array, 4 ];
$y = [ 0, [[ 100 ]], [ 20, 'b' ], $sub_array, 5 ];

$d = diff($x, $y, noU => 0);
$frozen_d = freeze($d);

$s = split_diff($d);
is_deeply($s, {a => $x,b => $y}, "complex arrays, noU => 0");

is($frozen_d, freeze($d), "original struct must remain unchanged");

$d = diff($x, $y, noU => 1);
$frozen_d = freeze($d);

$s = split_diff($d);
is_deeply($s, {a => [['a'],4],b => [['b'],5]}, "complex arrays, noU => 1");

is($frozen_d, freeze($d), "original struct must remain unchanged");

### hashes ###
is_deeply(
    split_diff(diff({}, {'k' => 'v'})),
    {a => {}, b => {'k' => 'v'}},
    'Old empty hash should be preserved by split_diff()'
);

is_deeply(
    split_diff(diff({'k' => 'v'}, {})),
    {a => {'k' => 'v'}, b => {}},
    'New empty hash should be preserved by split_diff()'
);


$x = { 'a' => 'a1', 'b' => { 'ba' => 'ba1', 'bb' => 'bb1' }, 'c' => 'c1' };
$y = { 'a' => 'a1', 'b' => { 'ba' => 'ba2', 'bb' => 'bb1' }, 'd' => 'd1' };

$d = diff($x, $y);
$frozen_d = freeze($d);

$s = split_diff($d);
is_deeply($s, {a => $x,b => $y}, "complex hashes, full diff");

is($frozen_d, freeze($d), "original struct must remain unchanged");

### mixed structures ###

$x = {
    'ak' => 'av',
    'bk' => [ 'bav', 'bbv', 'bcv', 'bdv' ],
    'ck' => { 'ca' => 'cav', 'cb' => 'cbv', 'cc' => 'ccv', 'cd' => 'cdv', 'ce' => 'cev' },
    'dk' => 'dav',
    'ek' => 'eav'
};
$y = {
    'ak' => 'an',
    'bk' => [ 'bav', 'bbn', 'bcn', 'bdv' ],
    'ck' => { 'ca' => 'can', 'cb' => 'cbv', 'cc' => 'ccv', 'cd' => 'cdn', 'cf' => 'cef' },
    'dk' => 'dav',
    'fk' => 'fav'
};

$d = diff($x, $y);
$frozen_d = freeze($d);

$s = split_diff($d);
is_deeply($s, {a => $x,b => $y}, "complex struct, full diff");

is($frozen_d, freeze($d), "original struct must remain unchanged");

$d = diff($x, $y, noU => 1);
$frozen_d = freeze($d);

$s = split_diff($d);
is_deeply(
    $s,
    {
        a => {ak => 'av',bk => ['bbv','bcv'],ck => {ca => 'cav',cd => 'cdv',ce => 'cev'},ek => 'eav'},
        b => {ak => 'an',bk => ['bbn','bcn'],ck => {ca => 'can',cd => 'cdn',cf => 'cef'},fk => 'fav'}
    },
    "complex struct, noU => 1"
);

is($frozen_d, freeze($d), "original struct must remain unchanged");
