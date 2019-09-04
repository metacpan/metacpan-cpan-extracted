#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::ToRoman';

diag 'E chords';

my $mtr = Music::ToRoman->new( scale_note => 'E' );
isa_ok $mtr, 'Music::ToRoman';

is $mtr->parse('E'), 'I', 'I';
is $mtr->parse('Esus4'), 'Isus4', 'Isus4';
is $mtr->parse('E sus4'), 'I sus4', 'I sus4';
is $mtr->parse('Eadd9'), 'Iadd9', 'Iadd9';
is $mtr->parse('E add9'), 'I add9', 'I add9';
is $mtr->parse('EMaj7'), 'Imaj7', 'Imaj7';
is $mtr->parse('E Maj7'), 'I maj7', 'I maj7';
is $mtr->parse('E+'), 'I+', 'I+';
is $mtr->parse('E xyz'), 'I xyz', 'I xyz';
is $mtr->parse('E5'), 'I5', 'I5';
is $mtr->parse('E64'), 'I64', 'I64';
is $mtr->parse('Fm'), 'bii', 'bii';
is $mtr->parse('F#m'), 'ii', 'ii';
is $mtr->parse('Gm'), 'biii', 'biii';
is $mtr->parse('G#m'), 'iii', 'iii';
is $mtr->parse('A'), 'IV', 'IV';
is $mtr->parse('Bb'), 'bV', 'bV';
is $mtr->parse('B'), 'V', 'V';
is $mtr->parse('B7'), 'V7', 'V7';
is $mtr->parse('Cm'), 'bvi', 'bvi';
is $mtr->parse('C#m'), 'vi', 'vi';
is $mtr->parse('Dm'), 'bvii', 'bvii';
is $mtr->parse('Do'), 'bviio', 'bviio';
is $mtr->parse('D#o'), 'viio', 'viio';
is $mtr->parse('D#dim'), 'viio', 'viio';
is $mtr->parse('D# dim'), 'vii o', 'vii o';

diag 'E/X chords';

is $mtr->parse('E/F'), 'I/bii', 'I/bii';
is $mtr->parse('E/F#'), 'I/ii', 'I/ii';
is $mtr->parse('E/G'), 'I/biii', 'I/biii';
is $mtr->parse('E/G#'), 'I/iii', 'I/iii';
is $mtr->parse('E/A'), 'I/IV', 'I/IV';
is $mtr->parse('E/Bb'), 'I/bV', 'I/bV';
is $mtr->parse('E/B'), 'I/V', 'I/V';
is $mtr->parse('E/C'), 'I/bvi', 'I/bvi';
is $mtr->parse('E/C#'), 'I/vi', 'I/vi';
is $mtr->parse('E/D'), 'I/bvii', 'I/bvii';
is $mtr->parse('E/D#'), 'I/vii', 'I/vii';
is $mtr->parse('Em xyz/D#'), 'i xyz/vii', 'i xyz/vii';

diag 'F# dorian';

$mtr = Music::ToRoman->new(
    scale_note => 'F#',
    scale_name => 'dorian',
    chords     => 0,
);

is $mtr->parse('F#'), 'i', 'i';
is $mtr->parse('G#'), 'ii', 'ii';
is $mtr->parse('A'), 'III', 'III';
is $mtr->parse('B'), 'IV', 'IV';
is $mtr->parse('C#'), 'v', 'v';
is $mtr->parse('D#'), 'vi', 'vi';
is $mtr->parse('E'), 'VII', 'VII';

diag 'G# phrygian';

$mtr = Music::ToRoman->new(
    scale_note => 'G#',
    scale_name => 'phrygian',
    chords     => 0,
);

is $mtr->parse('G#'), 'i', 'i';
is $mtr->parse('A'), 'II', 'II';
is $mtr->parse('B'), 'III', 'III';
is $mtr->parse('C#'), 'iv', 'iv';
is $mtr->parse('D#'), 'v', 'v';
is $mtr->parse('E'), 'VI', 'VI';
is $mtr->parse('F#'), 'vii', 'vii';

diag 'A lydian';

$mtr = Music::ToRoman->new(
    scale_note => 'A',
    scale_name => 'lydian',
    chords     => 0,
);

is $mtr->parse('A'), 'I', 'I';
is $mtr->parse('B'), 'II', 'II';
is $mtr->parse('C#'), 'iii', 'iii';
is $mtr->parse('D#'), 'iv', 'iv';
is $mtr->parse('E'), 'V', 'V';
is $mtr->parse('F#'), 'vi', 'vi';
is $mtr->parse('G#'), 'vii', 'vii';

diag 'B mixolydian';

$mtr = Music::ToRoman->new(
    scale_note => 'B',
    scale_name => 'mixolydian',
    chords     => 0,
);

is $mtr->parse('B'), 'I', 'I';
is $mtr->parse('C#'), 'ii', 'ii';
is $mtr->parse('D#'), 'iii', 'iii';
is $mtr->parse('E'), 'IV', 'IV';
is $mtr->parse('F#'), 'v', 'v';
is $mtr->parse('G#'), 'vi', 'vi';
is $mtr->parse('A'), 'VII', 'VII';

diag 'C# aeolian';

$mtr = Music::ToRoman->new(
    scale_note => 'C#',
    scale_name => 'aeolian',
    chords     => 0,
);

is $mtr->parse('C#'), 'i', 'i';
is $mtr->parse('D#'), 'ii', 'ii';
is $mtr->parse('E'), 'III', 'III';
is $mtr->parse('F#'), 'iv', 'iv';
is $mtr->parse('G#'), 'v', 'v';
is $mtr->parse('A'), 'VI', 'VI';
is $mtr->parse('B'), 'VII', 'VII';

diag 'D# locrian';

$mtr = Music::ToRoman->new(
    scale_note => 'D#',
    scale_name => 'locrian',
    chords     => 0,
);

is $mtr->parse('D#'), 'i', 'i';
is $mtr->parse('E'), 'II', 'II';
is $mtr->parse('F#'), 'iii', 'iii';
is $mtr->parse('G#'), 'iv', 'iv';
is $mtr->parse('A'), 'V', 'V';
is $mtr->parse('B'), 'VI', 'VI';
is $mtr->parse('C#'), 'vii', 'vii';

done_testing();
