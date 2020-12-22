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

$expect = [['d24','D#5'], ['d24','D5'], ['d24','C#5'], ['d24','D5']];
$got = $obj->turn('qn', 'D5', 1);
is_deeply $got, $expect, 'turn';
$expect = [['d24','C#5'], ['d24','D5'], ['d24','D#5'], ['d24','D5']];
$got = $obj->turn('qn', 'D5', -1);
is_deeply $got, $expect, 'turn invert';

$expect = [['d24','D5'], ['d24','D#5'], ['d24','D5'], ['d24','D#5']];
$got = $obj->trill('qn', 'D5', 2, 1);
is_deeply $got, $expect, 'trill upper';
$expect = [['d24','D5'], ['d24','C#5'], ['d24','D5'], ['d24','C#5']];
$got = $obj->trill('qn', 'D5', 2, -1);
is_deeply $got, $expect, 'trill lower';

$expect = [['d24','D5'], ['d24','D#5'], ['d48','D5']];
$got = $obj->mordent('qn', 'D5', 1);
is_deeply $got, $expect, 'mordent upper';
$expect = [['d24','D5'], ['d24','C#5'], ['d48','D5']];
$got = $obj->mordent('qn', 'D5', -1);
is_deeply $got, $expect, 'mordent lower';

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

$expect = [['d24','E5'], ['d24','D5'], ['d24','C5'], ['d24','D5']];
$got = $obj->turn('qn', 'D5', 1);
is_deeply $got, $expect, 'turn';
$expect = [['d24','C5'], ['d24','D5'], ['d24','E5'], ['d24','D5']];
$got = $obj->turn('qn', 'D5', -1);
is_deeply $got, $expect, 'turn invert';

$expect = [['d24','D5'], ['d24','E5'], ['d24','D5'], ['d24','E5']];
$got = $obj->trill('qn', 'D5', 2, 1);
is_deeply $got, $expect, 'trill upper';
$expect = [['d24','D5'], ['d24','C5'], ['d24','D5'], ['d24','C5']];
$got = $obj->trill('qn', 'D5', 2, -1);
is_deeply $got, $expect, 'trill lower';

$expect = [['d24','D5'], ['d24','E5'], ['d48','D5']];
$got = $obj->mordent('qn', 'D5', 1);
is_deeply $got, $expect, 'mordent upper';
$expect = [['d24','D5'], ['d24','C5'], ['d48','D5']];
$got = $obj->mordent('qn', 'D5', -1);
is_deeply $got, $expect, 'mordent lower';

done_testing();
