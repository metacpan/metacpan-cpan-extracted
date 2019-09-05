#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::ToRoman';

diag 'B chords';

my $mtr = Music::ToRoman->new( scale_note => 'B' );
isa_ok $mtr, 'Music::ToRoman';

is $mtr->parse('B'), 'I', 'I';
is $mtr->parse('Bsus4'), 'Isus4', 'Isus4';
is $mtr->parse('B sus4'), 'I sus4', 'I sus4';
is $mtr->parse('Badd9'), 'Iadd9', 'Iadd9';
is $mtr->parse('B add9'), 'I add9', 'I add9';
is $mtr->parse('BMaj7'), 'Imaj7', 'Imaj7';
is $mtr->parse('B Maj7'), 'I maj7', 'I maj7';
is $mtr->parse('B+'), 'I+', 'I+';
is $mtr->parse('B xyz'), 'I xyz', 'I xyz';
is $mtr->parse('B5'), 'I5', 'I5';
is $mtr->parse('B64'), 'I64', 'I64';
is $mtr->parse('Cm'), 'bii', 'bii';
is $mtr->parse('C#m'), 'ii', 'ii';
is $mtr->parse('Dm'), 'biii', 'biii';
is $mtr->parse('D#m'), 'iii', 'iii';
is $mtr->parse('E'), 'IV', 'IV';
is $mtr->parse('F'), 'bV', 'bV';
is $mtr->parse('F#'), 'V', 'V';
is $mtr->parse('F#7'), 'V7', 'V7';
is $mtr->parse('Gm'), 'bvi', 'bvi';
is $mtr->parse('G#m'), 'vi', 'vi';
is $mtr->parse('G#m7'), 'vi7', 'vi7';
is $mtr->parse('G#m7b5'), 'vi7b5', 'vi7b5';
is $mtr->parse('G#min7'), 'vimin7', 'vimin7';
is $mtr->parse('Am'), 'bvii', 'bvii';
is $mtr->parse('Ao'), 'bviio', 'bviio';
is $mtr->parse('A#o'), 'viio', 'viio';
is $mtr->parse('A#dim'), 'viio', 'viio';
is $mtr->parse('A# dim'), 'vii o', 'vii o';

diag 'B/X chords';

is $mtr->parse('B/C'), 'I/bii', 'I/bii';
is $mtr->parse('B/C#'), 'I/ii', 'I/ii';
is $mtr->parse('B/D'), 'I/biii', 'I/biii';
is $mtr->parse('B/D#'), 'I/iii', 'I/iii';
is $mtr->parse('B/E'), 'I/IV', 'I/IV';
is $mtr->parse('B/F'), 'I/bV', 'I/bV';
is $mtr->parse('B/F#'), 'I/V', 'I/V';
is $mtr->parse('B/G'), 'I/bvi', 'I/bvi';
is $mtr->parse('B/G#'), 'I/vi', 'I/vi';
is $mtr->parse('B/A'), 'I/bvii', 'I/bvii';
is $mtr->parse('B/A#'), 'I/vii', 'I/vii';
is $mtr->parse('Bm xyz/A#'), 'i xyz/vii', 'i xyz/vii';

diag 'C# dorian';

$mtr = Music::ToRoman->new(
    scale_note => 'C#',
    scale_name => 'dorian',
    chords     => 0,
);

is $mtr->parse('C#'), 'i', 'i';
is $mtr->parse('D#'), 'ii', 'ii';
is $mtr->parse('E'), 'III', 'III';
is $mtr->parse('F#'), 'IV', 'IV';
is $mtr->parse('G#'), 'v', 'v';
is $mtr->parse('A#'), 'vi', 'vi';
is $mtr->parse('B'), 'VII', 'VII';

diag 'D# phrygian';

$mtr = Music::ToRoman->new(
    scale_note => 'D#',
    scale_name => 'phrygian',
    chords     => 0,
);

is $mtr->parse('D#'), 'i', 'i';
is $mtr->parse('E'), 'II', 'II';
is $mtr->parse('F#'), 'III', 'III';
is $mtr->parse('G#'), 'iv', 'iv';
is $mtr->parse('A#'), 'v', 'v';
is $mtr->parse('B'), 'VI', 'VI';
is $mtr->parse('C#'), 'vii', 'vii';

diag 'E lydian';

$mtr = Music::ToRoman->new(
    scale_note => 'E',
    scale_name => 'lydian',
    chords     => 0,
);

is $mtr->parse('E'), 'I', 'I';
is $mtr->parse('F#'), 'II', 'II';
is $mtr->parse('G#'), 'iii', 'iii';
is $mtr->parse('A#'), 'iv', 'iv';
is $mtr->parse('B'), 'V', 'V';
is $mtr->parse('C#'), 'vi', 'vi';
is $mtr->parse('D#'), 'vii', 'vii';

diag 'F# mixolydian';

$mtr = Music::ToRoman->new(
    scale_note => 'F#',
    scale_name => 'mixolydian',
    chords     => 0,
);

is $mtr->parse('F#'), 'I', 'I';
is $mtr->parse('G#'), 'ii', 'ii';
is $mtr->parse('A#'), 'iii', 'iii';
is $mtr->parse('B'), 'IV', 'IV';
is $mtr->parse('C#'), 'v', 'v';
is $mtr->parse('D#'), 'vi', 'vi';
is $mtr->parse('E'), 'VII', 'VII';

diag 'G# aeolian';

$mtr = Music::ToRoman->new(
    scale_note => 'G#',
    scale_name => 'aeolian',
    chords     => 0,
);

is $mtr->parse('G#'), 'i', 'i';
is $mtr->parse('A#'), 'ii', 'ii';
is $mtr->parse('B'), 'III', 'III';
is $mtr->parse('C#'), 'iv', 'iv';
is $mtr->parse('D#'), 'v', 'v';
is $mtr->parse('E'), 'VI', 'VI';
is $mtr->parse('F#'), 'VII', 'VII';

diag 'A# locrian';

$mtr = Music::ToRoman->new(
    scale_note => 'A#',
    scale_name => 'locrian',
    chords     => 0,
);

is $mtr->parse('A#'), 'i', 'i';
is $mtr->parse('B'), 'II', 'II';
is $mtr->parse('C#'), 'iii', 'iii';
is $mtr->parse('D#'), 'iv', 'iv';
is $mtr->parse('E'), 'V', 'V';
is $mtr->parse('F#'), 'VI', 'VI';
is $mtr->parse('G#'), 'vii', 'vii';

done_testing();
