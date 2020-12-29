#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::MelodicDevice::Transposition';

my @notes = qw(C4 E4 D4 G4 C5);

my $obj = new_ok 'Music::MelodicDevice::Transposition';# => [ verbose => 1 ];
my $expect = ['D4','F#4','E4','A4','D5'];
my $got = $obj->transpose(2, \@notes);
is_deeply $got, $expect, 'transpose up 2';
$expect = ['E4','G#4','F#4','B4','E5'];
$got = $obj->transpose(4, \@notes);
is_deeply $got, $expect, 'transpose up 4';
$expect = ['A#3','D4','C4','F4','A#4'];
$got = $obj->transpose(-2, \@notes);
is_deeply $got, $expect, 'transpose down 2';
$expect = ['G#3','C4','A#3','D#4','G#4'];
$got = $obj->transpose(-4, \@notes);
is_deeply $got, $expect, 'transpose down 4';

$obj = new_ok 'Music::MelodicDevice::Transposition' => [
    scale_name => 'major',
#    verbose => 1,
];
$expect = ['E4','G4','F4','B4','E5'];
$got = $obj->transpose(2, \@notes);
is_deeply $got, $expect, 'transpose up 2';
$expect = ['G4','B4','A4','D5','G5'];
$got = $obj->transpose(4, \@notes);
is_deeply $got, $expect, 'transpose up 4';
$expect = ['A3','C4','B3','E4','A4'];
$got = $obj->transpose(-2, \@notes);
is_deeply $got, $expect, 'transpose down 2';
$expect = ['F3','A3','G3','C4','F4'];
$got = $obj->transpose(-4, \@notes);
is_deeply $got, $expect, 'transpose down 4';

@notes = ('C4','E4','D#4','G4','C5');
$expect = ['E4','G4',undef,'B4','E5'];
$got = $obj->transpose(2, \@notes);
is_deeply $got, $expect, 'transpose unknown';

done_testing();
