#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::ToRoman';

diag 'G chords';

my $mtr = Music::ToRoman->new( scale_note => 'G' );
isa_ok $mtr, 'Music::ToRoman';

is $mtr->parse('G'), 'I', 'I';
is $mtr->parse('Gsus4'), 'Isus4', 'Isus4';
is $mtr->parse('G sus4'), 'I sus4', 'I sus4';
is $mtr->parse('Gadd9'), 'Iadd9', 'Iadd9';
is $mtr->parse('G add9'), 'I add9', 'I add9';
is $mtr->parse('GMaj7'), 'Imaj7', 'Imaj7';
is $mtr->parse('G Maj7'), 'I maj7', 'I maj7';
is $mtr->parse('G+'), 'I+', 'I+';
is $mtr->parse('G xyz'), 'I xyz', 'I xyz';
is $mtr->parse('G5'), 'I5', 'I5';
is $mtr->parse('G64'), 'I64', 'I64';
is $mtr->parse('Abm'), 'bii', 'bii';
is $mtr->parse('Am'), 'ii', 'ii';
is $mtr->parse('Bbm'), 'biii', 'biii';
is $mtr->parse('Bm'), 'iii', 'iii';
is $mtr->parse('C'), 'IV', 'IV';
is $mtr->parse('Db'), 'bV', 'bV';
is $mtr->parse('D'), 'V', 'V';
is $mtr->parse('D7'), 'V7', 'V7';
is $mtr->parse('Ebm'), 'bvi', 'bvi';
is $mtr->parse('Em'), 'vi', 'vi';
is $mtr->parse('Fm'), 'bvii', 'bvii';
is $mtr->parse('Fo'), 'bviio', 'bviio';
is $mtr->parse('F#o'), 'viio', 'viio';
is $mtr->parse('F#dim'), 'viio', 'viio';
is $mtr->parse('F# dim'), 'vii o', 'vii o';

diag 'G/X chords';

is $mtr->parse('G/Ab'), 'I/bii', 'I/bii';
is $mtr->parse('G/A'), 'I/ii', 'I/ii';
is $mtr->parse('G/Bb'), 'I/biii', 'I/biii';
is $mtr->parse('G/B'), 'I/iii', 'I/iii';
is $mtr->parse('G/C'), 'I/IV', 'I/IV';
is $mtr->parse('G/Db'), 'I/bV', 'I/bV';
is $mtr->parse('G/D'), 'I/V', 'I/V';
is $mtr->parse('G/Eb'), 'I/bvi', 'I/bvi';
is $mtr->parse('G/E'), 'I/vi', 'I/vi';
is $mtr->parse('G/F'), 'I/bvii', 'I/bvii';
is $mtr->parse('G/F#'), 'I/vii', 'I/vii';
is $mtr->parse('Gm xyz/F#'), 'i xyz/vii', 'i xyz/vii';

diag 'A dorian';

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

diag 'B phrygian';

$mtr = Music::ToRoman->new(
    scale_note => 'B',
    scale_name => 'phrygian',
    chords     => 0,
);

is $mtr->parse('B'), 'i', 'i';
is $mtr->parse('C'), 'II', 'II';
is $mtr->parse('D'), 'III', 'III';
is $mtr->parse('E'), 'iv', 'iv';
is $mtr->parse('F#'), 'v', 'v';
is $mtr->parse('G'), 'VI', 'VI';
is $mtr->parse('A'), 'vii', 'vii';

diag 'C lydian';

$mtr = Music::ToRoman->new(
    scale_note => 'C',
    scale_name => 'lydian',
    chords     => 0,
);

is $mtr->parse('C'), 'I', 'I';
is $mtr->parse('D'), 'II', 'II';
is $mtr->parse('E'), 'iii', 'iii';
is $mtr->parse('F#'), 'iv', 'iv';
is $mtr->parse('G'), 'V', 'V';
is $mtr->parse('A'), 'vi', 'vi';
is $mtr->parse('B'), 'vii', 'vii';

diag 'D mixolydian';

$mtr = Music::ToRoman->new(
    scale_note => 'D',
    scale_name => 'mixolydian',
    chords     => 0,
);

is $mtr->parse('D'), 'I', 'I';
is $mtr->parse('E'), 'ii', 'ii';
is $mtr->parse('F#'), 'iii', 'iii';
is $mtr->parse('G'), 'IV', 'IV';
is $mtr->parse('A'), 'v', 'v';
is $mtr->parse('B'), 'vi', 'vi';
is $mtr->parse('C'), 'VII', 'VII';

diag 'E aeolian';

$mtr = Music::ToRoman->new(
    scale_note => 'E',
    scale_name => 'aeolian',
    chords     => 0,
);

is $mtr->parse('E'), 'i', 'i';
is $mtr->parse('F#'), 'ii', 'ii';
is $mtr->parse('G'), 'III', 'III';
is $mtr->parse('A'), 'iv', 'iv';
is $mtr->parse('B'), 'v', 'v';
is $mtr->parse('C'), 'VI', 'VI';
is $mtr->parse('D'), 'VII', 'VII';

diag 'F# locrian';

$mtr = Music::ToRoman->new(
    scale_note => 'F#',
    scale_name => 'locrian',
    chords     => 0,
);

is $mtr->parse('F#'), 'i', 'i';
is $mtr->parse('G'), 'II', 'II';
is $mtr->parse('A'), 'iii', 'iii';
is $mtr->parse('B'), 'iv', 'iv';
is $mtr->parse('C'), 'V', 'V';
is $mtr->parse('D'), 'VI', 'VI';
is $mtr->parse('E'), 'vii', 'vii';

done_testing();
