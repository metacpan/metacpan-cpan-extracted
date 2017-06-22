#!perl -T

use strict;
use warnings;
use Storable qw(freeze);
use Struct::Diff qw(diff split_diff);
use Test::More tests => 17;

local $Storable::canonical = 1; # to have equal snapshots for equal by data hashes

my ($a, $b, $d, $frozen_d, $s);

### garbage ###
eval { split_diff(undef) };
ok($@ =~ /^Unsupported diff struct passed/);

eval { split_diff({D => 'garbage'}) };
ok($@ =~ /^Value for 'D' status must be hash or array/);

$s = split_diff({garbage_as_a_status => 'garbage'});
is_deeply($s, {}, "diff: {garbage_as_a_status => 'garbage'}");

### primitives ###
$s = split_diff(diff(0, 0));
is_deeply($s, {a => 0,b => 0}, "0 vs 0");

$s = split_diff(diff(0, 1));
is_deeply($s, {a => 0,b => 1}, "0 vs 1");

### arrays ###
$d = diff([ 0 ], [ 0, 1 ]);

$s = split_diff($d);
is_deeply($s, {a => [0],b => [0,1]}, "[0] vs [0,1]");

$s = split_diff(diff([ 0, 1 ], [ 0 ]));
is_deeply($s, {a => [0,1],b => [0]}, "[0,1] vs [0]");

my $sub_array = [ 0, [ 11, 12 ], 2 ];
$a = [ 0, [[ 100 ]], [ 20, 'a' ], $sub_array, 4 ];
$b = [ 0, [[ 100 ]], [ 20, 'b' ], $sub_array, 5 ];

$d = diff($a, $b, noU => 0);
$frozen_d = freeze($d);

$s = split_diff($d);
is_deeply($s, {a => $a,b => $b}, "complex arrays, noU => 0");

is($frozen_d, freeze($d), "original struct must remain unchanged");

$d = diff($a, $b, noU => 1);
$frozen_d = freeze($d);

$s = split_diff($d);
is_deeply($s, {a => [['a'],4],b => [['b'],5]}, "complex arrays, noU => 1");

is($frozen_d, freeze($d), "original struct must remain unchanged");

### hashes ###

$a = { 'a' => 'a1', 'b' => { 'ba' => 'ba1', 'bb' => 'bb1' }, 'c' => 'c1' };
$b = { 'a' => 'a1', 'b' => { 'ba' => 'ba2', 'bb' => 'bb1' }, 'd' => 'd1' };

$d = diff($a, $b);
$frozen_d = freeze($d);

$s = split_diff($d);
is_deeply($s, {a => $a,b => $b}, "complex hashes, full diff");

is($frozen_d, freeze($d), "original struct must remain unchanged");

### mixed structures ###

$a = {
    'ak' => 'av',
    'bk' => [ 'bav', 'bbv', 'bcv', 'bdv' ],
    'ck' => { 'ca' => 'cav', 'cb' => 'cbv', 'cc' => 'ccv', 'cd' => 'cdv', 'ce' => 'cev' },
    'dk' => 'dav',
    'ek' => 'eav'
};
$b = {
    'ak' => 'an',
    'bk' => [ 'bav', 'bbn', 'bcn', 'bdv' ],
    'ck' => { 'ca' => 'can', 'cb' => 'cbv', 'cc' => 'ccv', 'cd' => 'cdn', 'cf' => 'cef' },
    'dk' => 'dav',
    'fk' => 'fav'
};

$d = diff($a, $b);
$frozen_d = freeze($d);

$s = split_diff($d);
is_deeply($s, {a => $a,b => $b}, "complex struct, full diff");

is($frozen_d, freeze($d), "original struct must remain unchanged");

$d = diff($a, $b, noU => 1);
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
