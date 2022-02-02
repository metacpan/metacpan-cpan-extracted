#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::MelodicDevice::Inversion';

my $obj = new_ok 'Music::MelodicDevice::Inversion';

# https://music.stackexchange.com/questions/32507/what-is-melodic-inversion-and-how-to-do-it/
my $notes = [qw(A4 C5 B4 A4 E5)];
my $expect = [qw(3 -1 -2 7)];
my $got = $obj->intervals($notes);
is_deeply $got, $expect, 'intervals';
$expect = ['E5','C#5','D5','E5','A4'];
$got = $obj->invert('E5', $notes);
is_deeply $got, $expect, 'invert';

my $nums = [qw(69 72 71 69 76)];
$expect = [qw(3 -1 -2 7)];
$got = $obj->intervals($nums);
is_deeply $got, $expect, 'intervals';
$expect = [qw(76 73 74 76 69)];
$got = $obj->invert(76, $notes);
is_deeply $got, $expect, 'invert';

# https://en.wikipedia.org/wiki/Inversion_(music)#Melodies
$notes = ['A#4','E4','F#4','D#4','F4','A4','D5','C#5','G4','G#4','B4','C5'];
$expect = [qw(-6 2 -3 2 4 5 -1 -6 1 3 1)];
$got = $obj->intervals($notes);
is_deeply $got, $expect, 'intervals';
$expect = ['A#4','E5','D5','F5','D#5','B4','F#4','G4','C#5','C5','A4','G#4'];
$got = $obj->invert('A#4', $notes);
is_deeply $got, $expect, 'invert';

$notes = [qw(C4 E4 D4 G4 C5)];
$expect = [qw(4 -2 5 5)];
$got = $obj->intervals($notes);
is_deeply $got, $expect, 'intervals';
$expect = ['C4','G#3','A#3','F3','C3'];
$got = $obj->invert('C4', $notes);
is_deeply $got, $expect, 'invert';

$obj = new_ok 'Music::MelodicDevice::Inversion' => [ scale_name => 'major' ];
$expect = [qw(2 -1 3 3)];
$got = $obj->intervals($notes);
is_deeply $got, $expect, 'intervals';
$expect = [qw(C4 A3 B3 F3 C3)];
$got = $obj->invert('C4', $notes);
is_deeply $got, $expect, 'invert';

# https://en.wikipedia.org/wiki/Inversion_(music)#Melodies
$notes = [qw(G4 A4 G4 F4 G4 A4 B4 A4 G4 A4)];
$expect = [qw(1 -1 -1 1 1 1 -1 -1 1)];
$got = $obj->intervals($notes);
is_deeply $got, $expect, 'intervals';
$expect = [qw(D3 C3 D3 E3 D3 C3 B2 C3 D3 C3)];
$got = $obj->invert('D3', $notes);
is_deeply $got, $expect, 'invert';

done_testing();
