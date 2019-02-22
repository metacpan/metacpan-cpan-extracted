#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::ToRoman';

my $mtr = Music::ToRoman->new(
    scale_note => 'A',
    scale_name => 'minor',
);
isa_ok $mtr, 'Music::ToRoman';

is $mtr->parse('Am'), 'i', 'i';
is $mtr->parse('Bb'), 'bII', 'bII';
is $mtr->parse('B'), 'II', 'II';
is $mtr->parse('Bo'), 'iio', 'iio';
is $mtr->parse('Bdim'), 'iio', 'iio';
is $mtr->parse('B dim'), 'ii o', 'ii o';
is $mtr->parse('Bmsus4'), 'iisus4', 'iisus4';
is $mtr->parse('Bm sus4'), 'ii sus4', 'ii sus4';
is $mtr->parse('CM'), 'III', 'III';
is $mtr->parse('Cm9/G'), 'iii9/VII', 'iii9/VII';
is $mtr->parse('Cm9/Bb'), 'iii9/bii', 'iii9/bii';
is $mtr->parse('DMaj7'), 'IVmaj7', 'IVmaj7';
is $mtr->parse('D Maj7'), 'IV maj7', 'IV maj7';
is $mtr->parse('E7'), 'V7', 'V7';
is $mtr->parse('Em7'), 'v7', 'v7';
is $mtr->parse('Emin7'), 'vmin7', 'vmin7';
is $mtr->parse('E min7'), 'v min7', 'v min7';
is $mtr->parse('F+'), 'VI+', 'VI+';
is $mtr->parse('Gadd9'), 'VIIadd9', 'VIIadd9';
is $mtr->parse('G add9'), 'VII add9', 'VII add9';
is $mtr->parse('G xyz'), 'VII xyz', 'VII xyz';

$mtr = Music::ToRoman->new(
    scale_note => 'A',
    scale_name => 'dorian',
    chords     => 0,
);
is $mtr->parse('A'), 'i', 'i';
is $mtr->parse('B'), 'ii', 'ii';
is $mtr->parse('C'), 'III', 'III';
is $mtr->parse('D'), 'IV', 'IV';
is $mtr->parse('E'), 'v', 'v';
is $mtr->parse('F#'), 'vi', 'vi';
is $mtr->parse('G'), 'VII', 'VII';

is $mtr->parse('A7'), 'i7', 'i7';
is $mtr->parse('B+'), 'ii+', 'ii+'; # Bogus chord
is $mtr->parse('Co'), 'IIIo', 'IIIo'; # Bogus chord
is $mtr->parse('Dmin7'), 'IVmin7', 'IVmin7'; # Bogus chord
is $mtr->parse('EMaj7'), 'vmaj7', 'vmaj7'; # Bogus chord
is $mtr->parse('Em'), 'v', 'v';
is $mtr->parse('F#/G'), 'vi/VII', 'vi/VII';
is $mtr->parse('Gb'), 'bVII', 'bVII';

done_testing();
