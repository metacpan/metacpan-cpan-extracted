#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::MelodicDevice::Ornamentation';

my $obj = new_ok 'Music::MelodicDevice::Ornamentation';# => [ verbose => 1 ];

my $expect = [['d12', 'D#5'], ['d84', 'D5']];
my $got = $obj->grace_note('qn', 'D5', 1);
is_deeply $got, $expect, 'grace_note upper';
$expect = [['d12', 'D5'], ['d84', 'D5']];
$got = $obj->grace_note('qn', 'D5', 0);
is_deeply $got, $expect, 'grace_note same';
$expect = [['d12', 'C#5'], ['d84', 'D5']];
$got = $obj->grace_note('qn', 'D5', -1);
is_deeply $got, $expect, 'grace_note lower';

$expect = [['d12', 75], ['d84', 74]];
$got = $obj->grace_note('qn', 74, 1);
is_deeply $got, $expect, 'grace_note upper';
$expect = [['d12', 74], ['d84', 74]];
$got = $obj->grace_note('qn', 74, 0);
is_deeply $got, $expect, 'grace_note same';
$expect = [['d12', 73], ['d84', 74]];
$got = $obj->grace_note('qn', 74, -1);
is_deeply $got, $expect, 'grace_note lower';

$expect = [['d24','D#5'], ['d24','D5'], ['d24','C#5'], ['d24','D5']];
$got = $obj->turn('qn', 'D5', 1);
is_deeply $got, $expect, 'turn';
$expect = [['d24','C#5'], ['d24','D5'], ['d24','D#5'], ['d24','D5']];
$got = $obj->turn('qn', 'D5', -1);
is_deeply $got, $expect, 'turn invert';

$expect = [['d24',75], ['d24',74], ['d24',73], ['d24',74]];
$got = $obj->turn('qn', 74, 1);
is_deeply $got, $expect, 'turn';
$expect = [['d24',73], ['d24',74], ['d24',75], ['d24',74]];
$got = $obj->turn('qn', 74, -1);
is_deeply $got, $expect, 'turn invert';

$expect = [['d24','D5'], ['d24','D#5'], ['d24','D5'], ['d24','D#5']];
$got = $obj->trill('qn', 'D5', 2, 1);
is_deeply $got, $expect, 'trill upper';
$expect = [['d24','D5'], ['d24','C#5'], ['d24','D5'], ['d24','C#5']];
$got = $obj->trill('qn', 'D5', 2, -1);
is_deeply $got, $expect, 'trill lower';

$expect = [['d24',74], ['d24',75], ['d24',74], ['d24',75]];
$got = $obj->trill('qn', 74, 2, 1);
is_deeply $got, $expect, 'trill upper';
$expect = [['d24',74], ['d24',73], ['d24',74], ['d24',73]];
$got = $obj->trill('qn', 74, 2, -1);
is_deeply $got, $expect, 'trill lower';

$expect = [['d24','D5'], ['d24','D#5'], ['d48','D5']];
$got = $obj->mordent('qn', 'D5', 1);
is_deeply $got, $expect, 'mordent upper';
$expect = [['d24','D5'], ['d24','C#5'], ['d48','D5']];
$got = $obj->mordent('qn', 'D5', -1);
is_deeply $got, $expect, 'mordent lower';

$expect = [['d24',74], ['d24',75], ['d48',74]];
$got = $obj->mordent('qn', 74, 1);
is_deeply $got, $expect, 'mordent upper';
$expect = [['d24',74], ['d24',73], ['d48',74]];
$got = $obj->mordent('qn', 74, -1);
is_deeply $got, $expect, 'mordent lower';

$expect = [ ['d24','D5'], ['d24','D#5'], ['d24','E5'], ['d24','F5'] ];
$got = $obj->slide('qn', 'D5', 'F5');
is_deeply $got, $expect, 'slide up';
$expect = [ ['d24','D5'], ['d24','C#5'], ['d24','C5'], ['d24','B4'] ];
$got = $obj->slide('qn', 'D5', 'B4');
is_deeply $got, $expect, 'slide down';

$expect = [ ['d24',74], ['d24',75], ['d24',76], ['d24',77] ];
$got = $obj->slide('qn', 74, 'F5');
is_deeply $got, $expect, 'slide up';
$expect = [ ['d24',74], ['d24',73], ['d24',72], ['d24',71] ];
$got = $obj->slide('qn', 74, 'B4');
is_deeply $got, $expect, 'slide down';

$obj = new_ok 'Music::MelodicDevice::Ornamentation' => [ scale_name => 'major' ];

$expect = [['d12', 'E5'], ['d84', 'D5']];
$got = $obj->grace_note('qn', 'D5', 1);
is_deeply $got, $expect, 'grace_note upper';
$expect = [['d12', 'D5'], ['d84', 'D5']];
$got = $obj->grace_note('qn', 'D5', 0);
is_deeply $got, $expect, 'grace_note same';
$expect = [['d12', 'C5'], ['d84', 'D5']];
$got = $obj->grace_note('qn', 'D5', -1);
is_deeply $got, $expect, 'grace_note lower';

$expect = [['d12', 76], ['d84', 74]];
$got = $obj->grace_note('qn', 74, 1);
is_deeply $got, $expect, 'grace_note upper';
$expect = [['d12', 74], ['d84', 74]];
$got = $obj->grace_note('qn', 74, 0);
is_deeply $got, $expect, 'grace_note same';
$expect = [['d12', 72], ['d84', 74]];
$got = $obj->grace_note('qn', 74, -1);
is_deeply $got, $expect, 'grace_note lower';

$expect = [['d24','E5'], ['d24','D5'], ['d24','C5'], ['d24','D5']];
$got = $obj->turn('qn', 'D5', 1);
is_deeply $got, $expect, 'turn';
$expect = [['d24','C5'], ['d24','D5'], ['d24','E5'], ['d24','D5']];
$got = $obj->turn('qn', 'D5', -1);
is_deeply $got, $expect, 'turn invert';

$expect = [['d24',76], ['d24',74], ['d24',72], ['d24',74]];
$got = $obj->turn('qn', 74, 1);
is_deeply $got, $expect, 'turn';
$expect = [['d24',72], ['d24',74], ['d24',76], ['d24',74]];
$got = $obj->turn('qn', 74, -1);
is_deeply $got, $expect, 'turn invert';

$expect = [['d24','D5'], ['d24','E5'], ['d24','D5'], ['d24','E5']];
$got = $obj->trill('qn', 'D5', 2, 1);
is_deeply $got, $expect, 'trill upper';
$expect = [['d24','D5'], ['d24','C5'], ['d24','D5'], ['d24','C5']];
$got = $obj->trill('qn', 'D5', 2, -1);
is_deeply $got, $expect, 'trill lower';

$expect = [['d24',74], ['d24',76], ['d24',74], ['d24',76]];
$got = $obj->trill('qn', 74, 2, 1);
is_deeply $got, $expect, 'trill upper';
$expect = [['d24',74], ['d24',72], ['d24',74], ['d24',72]];
$got = $obj->trill('qn', 74, 2, -1);
is_deeply $got, $expect, 'trill lower';

$expect = [['d24','D5'], ['d24','E5'], ['d48','D5']];
$got = $obj->mordent('qn', 'D5', 1);
is_deeply $got, $expect, 'mordent upper';
$expect = [['d24','D5'], ['d24','C5'], ['d48','D5']];
$got = $obj->mordent('qn', 'D5', -1);
is_deeply $got, $expect, 'mordent lower';

$expect = [['d24',74], ['d24',76], ['d48',74]];
$got = $obj->mordent('qn', 74, 1);
is_deeply $got, $expect, 'mordent upper';
$expect = [['d24',74], ['d24',72], ['d48',74]];
$got = $obj->mordent('qn', 74, -1);
is_deeply $got, $expect, 'mordent lower';

$obj = new_ok 'Music::MelodicDevice::Ornamentation' => [
    scale_note => 'D',
    scale_name => 'major',
#    verbose => 1,
];

$expect = [['d12', 'E5'], ['d84', 'D5']];
$got = $obj->grace_note('qn', 'D5', 1);
is_deeply $got, $expect, 'grace_note upper';
$expect = [['d12', 'D5'], ['d84', 'D5']];
$got = $obj->grace_note('qn', 'D5', 0);
is_deeply $got, $expect, 'grace_note same';
$expect = [['d12', 'C#5'], ['d84', 'D5']];
$got = $obj->grace_note('qn', 'D5', -1);
is_deeply $got, $expect, 'grace_note lower';

$expect = [['d12', 76], ['d84', 74]];
$got = $obj->grace_note('qn', 74, 1);
is_deeply $got, $expect, 'grace_note upper';
$expect = [['d12', 74], ['d84', 74]];
$got = $obj->grace_note('qn', 74, 0);
is_deeply $got, $expect, 'grace_note same';
$expect = [['d12', 73], ['d84', 74]];
$got = $obj->grace_note('qn', 74, -1);
is_deeply $got, $expect, 'grace_note lower';

$expect = [['d24','E5'], ['d24','D5'], ['d24','C#5'], ['d24','D5']];
$got = $obj->turn('qn', 'D5', 1);
is_deeply $got, $expect, 'turn';
$expect = [['d24','C#5'], ['d24','D5'], ['d24','E5'], ['d24','D5']];
$got = $obj->turn('qn', 'D5', -1);
is_deeply $got, $expect, 'turn invert';

$expect = [['d24',76], ['d24',74], ['d24',73], ['d24',74]];
$got = $obj->turn('qn', 74, 1);
is_deeply $got, $expect, 'turn';
$expect = [['d24',73], ['d24',74], ['d24',76], ['d24',74]];
$got = $obj->turn('qn', 74, -1);
is_deeply $got, $expect, 'turn invert';

$expect = [['d24','D5'], ['d24','E5'], ['d24','D5'], ['d24','E5']];
$got = $obj->trill('qn', 'D5', 2, 1);
is_deeply $got, $expect, 'trill upper';
$expect = [['d24','D5'], ['d24','C#5'], ['d24','D5'], ['d24','C#5']];
$got = $obj->trill('qn', 'D5', 2, -1);
is_deeply $got, $expect, 'trill lower';

$expect = [['d24',74], ['d24',76], ['d24',74], ['d24',76]];
$got = $obj->trill('qn', 74, 2, 1);
is_deeply $got, $expect, 'trill upper';
$expect = [['d24',74], ['d24',73], ['d24',74], ['d24',73]];
$got = $obj->trill('qn', 74, 2, -1);
is_deeply $got, $expect, 'trill lower';

$expect = [['d24','D5'], ['d24','E5'], ['d48','D5']];
$got = $obj->mordent('qn', 'D5', 1);
is_deeply $got, $expect, 'mordent upper';
$expect = [['d24','D5'], ['d24','C#5'], ['d48','D5']];
$got = $obj->mordent('qn', 'D5', -1);
is_deeply $got, $expect, 'mordent lower';

$expect = [['d24',74], ['d24',76], ['d48',74]];
$got = $obj->mordent('qn', 74, 1);
is_deeply $got, $expect, 'mordent upper';
$expect = [['d24',74], ['d24',73], ['d48',74]];
$got = $obj->mordent('qn', 74, -1);
is_deeply $got, $expect, 'mordent lower';

done_testing();
