#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::ToRoman';

diag 'A chords';

my $mtr = Music::ToRoman->new( scale_note => 'A' );
isa_ok $mtr, 'Music::ToRoman';

is $mtr->parse('A'), 'I', 'I';
is $mtr->parse('Asus4'), 'Isus4', 'Isus4';
is $mtr->parse('A sus4'), 'I sus4', 'I sus4';
is $mtr->parse('Aadd9'), 'Iadd9', 'Iadd9';
is $mtr->parse('A add9'), 'I add9', 'I add9';
is $mtr->parse('AMaj7'), 'Imaj7', 'Imaj7';
is $mtr->parse('A Maj7'), 'I maj7', 'I maj7';
is $mtr->parse('A+'), 'I+', 'I+';
is $mtr->parse('A xyz'), 'I xyz', 'I xyz';
is $mtr->parse('A5'), 'I5', 'I5';
is $mtr->parse('A64'), 'I64', 'I64';
is $mtr->parse('Bbm'), 'bii', 'bii';
is $mtr->parse('Bm'), 'ii', 'ii';
is $mtr->parse('Cm'), 'biii', 'biii';
is $mtr->parse('C#m'), 'iii', 'iii';
is $mtr->parse('D'), 'IV', 'IV';
is $mtr->parse('Eb'), 'bV', 'bV';
is $mtr->parse('E'), 'V', 'V';
is $mtr->parse('E7'), 'V7', 'V7';
is $mtr->parse('Fm'), 'bvi', 'bvi';
is $mtr->parse('F#m'), 'vi', 'vi';
is $mtr->parse('Gm'), 'bvii', 'bvii';
is $mtr->parse('Go'), 'bviio', 'bviio';
is $mtr->parse('G#o'), 'viio', 'viio';
is $mtr->parse('G#dim'), 'viio', 'viio';
is $mtr->parse('G# dim'), 'vii o', 'vii o';

diag 'A/X chords';

is $mtr->parse('A/Bb'), 'I/bii', 'I/bii';
is $mtr->parse('A/B'), 'I/ii', 'I/ii';
is $mtr->parse('A/C'), 'I/biii', 'I/biii';
is $mtr->parse('A/C#'), 'I/iii', 'I/iii';
is $mtr->parse('A/D'), 'I/IV', 'I/IV';
is $mtr->parse('A/Eb'), 'I/bV', 'I/bV';
is $mtr->parse('A/E'), 'I/V', 'I/V';
is $mtr->parse('A/F'), 'I/bvi', 'I/bvi';
is $mtr->parse('A/F#'), 'I/vi', 'I/vi';
is $mtr->parse('A/G'), 'I/bvii', 'I/bvii';
is $mtr->parse('A/G#'), 'I/vii', 'I/vii';
is $mtr->parse('Am xyz/G#'), 'i xyz/vii', 'i xyz/vii';

diag 'B dorian';

$mtr = Music::ToRoman->new(
    scale_note => 'B',
    scale_name => 'dorian',
    chords     => 0,
);

is $mtr->parse('B'), 'i', 'i';
is $mtr->parse('C#'), 'ii', 'ii';
is $mtr->parse('D'), 'III', 'III';
is $mtr->parse('E'), 'IV', 'IV';
is $mtr->parse('F#'), 'v', 'v';
is $mtr->parse('G#'), 'vi', 'vi';
is $mtr->parse('A'), 'VII', 'VII';

diag 'C# phrygian';

$mtr = Music::ToRoman->new(
    scale_note => 'C#',
    scale_name => 'phrygian',
    chords     => 0,
);

is $mtr->parse('C#'), 'i', 'i';
is $mtr->parse('D'), 'II', 'II';
is $mtr->parse('E'), 'III', 'III';
is $mtr->parse('F#'), 'iv', 'iv';
is $mtr->parse('G#'), 'v', 'v';
is $mtr->parse('A'), 'VI', 'VI';
is $mtr->parse('B'), 'vii', 'vii';

diag 'D lydian';

$mtr = Music::ToRoman->new(
    scale_note => 'D',
    scale_name => 'lydian',
    chords     => 0,
);

is $mtr->parse('D'), 'I', 'I';
is $mtr->parse('E'), 'II', 'II';
is $mtr->parse('F#'), 'iii', 'iii';
is $mtr->parse('G#'), 'iv', 'iv';
is $mtr->parse('A'), 'V', 'V';
is $mtr->parse('B'), 'vi', 'vi';
is $mtr->parse('C#'), 'vii', 'vii';

diag 'E mixolydian';

$mtr = Music::ToRoman->new(
    scale_note => 'E',
    scale_name => 'mixolydian',
    chords     => 0,
);

is $mtr->parse('E'), 'I', 'I';
is $mtr->parse('F#'), 'ii', 'ii';
is $mtr->parse('G#'), 'iii', 'iii';
is $mtr->parse('A'), 'IV', 'IV';
is $mtr->parse('B'), 'v', 'v';
is $mtr->parse('C#'), 'vi', 'vi';
is $mtr->parse('D'), 'VII', 'VII';

diag 'F# aeolian';

$mtr = Music::ToRoman->new(
    scale_note => 'F#',
    scale_name => 'aeolian',
    chords     => 0,
);

is $mtr->parse('F#'), 'i', 'i';
is $mtr->parse('G#'), 'ii', 'ii';
is $mtr->parse('A'), 'III', 'III';
is $mtr->parse('B'), 'iv', 'iv';
is $mtr->parse('C#'), 'v', 'v';
is $mtr->parse('D'), 'VI', 'VI';
is $mtr->parse('E'), 'VII', 'VII';

diag 'G# locrian';

$mtr = Music::ToRoman->new(
    scale_note => 'G#',
    scale_name => 'locrian',
    chords     => 0,
);

is $mtr->parse('G#'), 'i', 'i';
is $mtr->parse('A'), 'II', 'II';
is $mtr->parse('B'), 'iii', 'iii';
is $mtr->parse('C#'), 'iv', 'iv';
is $mtr->parse('D'), 'V', 'V';
is $mtr->parse('E'), 'VI', 'VI';
is $mtr->parse('F#'), 'vii', 'vii';

done_testing();
