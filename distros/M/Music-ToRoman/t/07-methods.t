#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::ToRoman';

diag 'F# chords';

my $mtr = Music::ToRoman->new( scale_note => 'F#' );
isa_ok $mtr, 'Music::ToRoman';

is $mtr->parse('F#'), 'I', 'I';
is $mtr->parse('F#sus4'), 'Isus4', 'Isus4';
is $mtr->parse('F# sus4'), 'I sus4', 'I sus4';
is $mtr->parse('F#add9'), 'Iadd9', 'Iadd9';
is $mtr->parse('F# add9'), 'I add9', 'I add9';
is $mtr->parse('F#Maj7'), 'Imaj7', 'Imaj7';
is $mtr->parse('F# Maj7'), 'I maj7', 'I maj7';
is $mtr->parse('F#+'), 'I+', 'I+';
is $mtr->parse('F# xyz'), 'I xyz', 'I xyz';
is $mtr->parse('F#5'), 'I5', 'I5';
is $mtr->parse('F#64'), 'I64', 'I64';
is $mtr->parse('Gm'), 'bii', 'bii';
is $mtr->parse('G#m'), 'ii', 'ii';
is $mtr->parse('Am'), 'biii', 'biii';
is $mtr->parse('A#m'), 'iii', 'iii';
is $mtr->parse('B'), 'IV', 'IV';
is $mtr->parse('C'), 'bV', 'bV';
is $mtr->parse('C#'), 'V', 'V';
is $mtr->parse('C#7'), 'V7', 'V7';
is $mtr->parse('Dm'), 'bvi', 'bvi';
is $mtr->parse('D#m'), 'vi', 'vi';
is $mtr->parse('Em'), 'bvii', 'bvii';
is $mtr->parse('Eo'), 'bviio', 'bviio';
is $mtr->parse('E#o'), 'viio', 'viio';
is $mtr->parse('E#dim'), 'viio', 'viio';
is $mtr->parse('E# dim'), 'vii o', 'vii o';

diag 'F#/X chords';

is $mtr->parse('F#/G'), 'I/bii', 'I/bii';
is $mtr->parse('F#/G#'), 'I/ii', 'I/ii';
is $mtr->parse('F#/A'), 'I/biii', 'I/biii';
is $mtr->parse('F#/A#'), 'I/iii', 'I/iii';
is $mtr->parse('F#/B'), 'I/IV', 'I/IV';
is $mtr->parse('F#/C'), 'I/bV', 'I/bV';
is $mtr->parse('F#/C#'), 'I/V', 'I/V';
is $mtr->parse('F#/D'), 'I/bvi', 'I/bvi';
is $mtr->parse('F#/D#'), 'I/vi', 'I/vi';
is $mtr->parse('F#/E'), 'I/bvii', 'I/bvii';
is $mtr->parse('F#/E#'), 'I/vii', 'I/vii';
is $mtr->parse('F#m xyz/E#'), 'i xyz/vii', 'i xyz/vii';

diag 'G# dorian';

$mtr = Music::ToRoman->new(
    scale_note => 'G#',
    scale_name => 'dorian',
    chords     => 0,
);

is $mtr->parse('G#'), 'i', 'i';
is $mtr->parse('A#'), 'ii', 'ii';
is $mtr->parse('B'), 'III', 'III';
is $mtr->parse('C#'), 'IV', 'IV';
is $mtr->parse('D#'), 'v', 'v';
is $mtr->parse('E#'), 'vi', 'vi';
is $mtr->parse('F#'), 'VII', 'VII';

diag 'A# phrygian';

$mtr = Music::ToRoman->new(
    scale_note => 'A#',
    scale_name => 'phrygian',
    chords     => 0,
);

is $mtr->parse('A#'), 'i', 'i';
is $mtr->parse('B'), 'II', 'II';
is $mtr->parse('C#'), 'III', 'III';
is $mtr->parse('D#'), 'iv', 'iv';
is $mtr->parse('E#'), 'v', 'v';
is $mtr->parse('F#'), 'VI', 'VI';
is $mtr->parse('G#'), 'vii', 'vii';

diag 'B lydian';

$mtr = Music::ToRoman->new(
    scale_note => 'B',
    scale_name => 'lydian',
    chords     => 0,
);

is $mtr->parse('B'), 'I', 'I';
is $mtr->parse('C#'), 'II', 'II';
is $mtr->parse('D#'), 'iii', 'iii';
is $mtr->parse('E#'), 'iv', 'iv';
is $mtr->parse('F#'), 'V', 'V';
is $mtr->parse('G#'), 'vi', 'vi';
is $mtr->parse('A#'), 'vii', 'vii';

diag 'C# mixolydian';

$mtr = Music::ToRoman->new(
    scale_note => 'C#',
    scale_name => 'mixolydian',
    chords     => 0,
);

is $mtr->parse('C#'), 'I', 'I';
is $mtr->parse('D#'), 'ii', 'ii';
is $mtr->parse('E#'), 'iii', 'iii';
is $mtr->parse('F#'), 'IV', 'IV';
is $mtr->parse('G#'), 'v', 'v';
is $mtr->parse('A#'), 'vi', 'vi';
is $mtr->parse('B'), 'VII', 'VII';

diag 'D# aeolian';

$mtr = Music::ToRoman->new(
    scale_note => 'D#',
    scale_name => 'aeolian',
    chords     => 0,
);

is $mtr->parse('D#'), 'i', 'i';
is $mtr->parse('E#'), 'ii', 'ii';
is $mtr->parse('F#'), 'III', 'III';
is $mtr->parse('G#'), 'iv', 'iv';
is $mtr->parse('A#'), 'v', 'v';
is $mtr->parse('B'), 'VI', 'VI';
is $mtr->parse('C#'), 'VII', 'VII';

diag 'E# locrian';

$mtr = Music::ToRoman->new(
    scale_note => 'E#',
    scale_name => 'locrian',
    chords     => 0,
);

is $mtr->parse('E#'), 'i', 'i';
is $mtr->parse('F#'), 'II', 'II';
is $mtr->parse('G#'), 'iii', 'iii';
is $mtr->parse('A#'), 'iv', 'iv';
is $mtr->parse('B'), 'V', 'V';
is $mtr->parse('C#'), 'VI', 'VI';
is $mtr->parse('D#'), 'vii', 'vii';

diag 'Gb chords';

$mtr = Music::ToRoman->new( scale_note => 'Gb' );
isa_ok $mtr, 'Music::ToRoman';

is $mtr->parse('Gb'), 'I', 'I';
is $mtr->parse('Gbsus4'), 'Isus4', 'Isus4';
is $mtr->parse('Gb sus4'), 'I sus4', 'I sus4';
is $mtr->parse('Gbadd9'), 'Iadd9', 'Iadd9';
is $mtr->parse('Gb add9'), 'I add9', 'I add9';
is $mtr->parse('GbMaj7'), 'Imaj7', 'Imaj7';
is $mtr->parse('Gb Maj7'), 'I maj7', 'I maj7';
is $mtr->parse('Gb+'), 'I+', 'I+';
is $mtr->parse('Gb xyz'), 'I xyz', 'I xyz';
is $mtr->parse('Gb5'), 'I5', 'I5';
is $mtr->parse('Gb64'), 'I64', 'I64';
is $mtr->parse('Gm'), 'bii', 'bii';
is $mtr->parse('Abm'), 'ii', 'ii';
is $mtr->parse('Am'), 'biii', 'biii';
is $mtr->parse('Bbm'), 'iii', 'iii';
is $mtr->parse('Cb'), 'IV', 'IV';
is $mtr->parse('C'), 'bV', 'bV';
is $mtr->parse('Db'), 'V', 'V';
is $mtr->parse('Db7'), 'V7', 'V7';
is $mtr->parse('Dm'), 'bvi', 'bvi';
is $mtr->parse('Ebm'), 'vi', 'vi';
is $mtr->parse('Em'), 'bvii', 'bvii';
is $mtr->parse('Eo'), 'bviio', 'bviio';
is $mtr->parse('Fo'), 'viio', 'viio';
is $mtr->parse('Fdim'), 'viio', 'viio';
is $mtr->parse('F dim'), 'vii o', 'vii o';

diag 'Gb/X chords';

is $mtr->parse('Gb/G'), 'I/bii', 'I/bii';
is $mtr->parse('Gb/Ab'), 'I/ii', 'I/ii';
is $mtr->parse('Gb/A'), 'I/biii', 'I/biii';
is $mtr->parse('Gb/Bb'), 'I/iii', 'I/iii';
is $mtr->parse('Gb/Cb'), 'I/IV', 'I/IV';
is $mtr->parse('Gb/C'), 'I/bV', 'I/bV';
is $mtr->parse('Gb/Db'), 'I/V', 'I/V';
is $mtr->parse('Gb/D'), 'I/bvi', 'I/bvi';
is $mtr->parse('Gb/Eb'), 'I/vi', 'I/vi';
is $mtr->parse('Gb/E'), 'I/bvii', 'I/bvii';
is $mtr->parse('Gb/F'), 'I/vii', 'I/vii';
is $mtr->parse('Gbm xyz/F'), 'i xyz/vii', 'i xyz/vii';

diag 'Ab dorian';

$mtr = Music::ToRoman->new(
    scale_note => 'Ab',
    scale_name => 'dorian',
    chords     => 0,
);

is $mtr->parse('Ab'), 'i', 'i';
is $mtr->parse('Bb'), 'ii', 'ii';
is $mtr->parse('Cb'), 'III', 'III';
is $mtr->parse('Db'), 'IV', 'IV';
is $mtr->parse('Eb'), 'v', 'v';
is $mtr->parse('F'), 'vi', 'vi';
is $mtr->parse('Gb'), 'VII', 'VII';

diag 'Bb phrygian';

$mtr = Music::ToRoman->new(
    scale_note => 'Bb',
    scale_name => 'phrygian',
    chords     => 0,
);

is $mtr->parse('Bb'), 'i', 'i';
is $mtr->parse('Cb'), 'II', 'II';
is $mtr->parse('Db'), 'III', 'III';
is $mtr->parse('Eb'), 'iv', 'iv';
is $mtr->parse('F'), 'v', 'v';
is $mtr->parse('Gb'), 'VI', 'VI';
is $mtr->parse('Ab'), 'vii', 'vii';

diag 'Cb lydian';

$mtr = Music::ToRoman->new(
    scale_note => 'Cb',
    scale_name => 'lydian',
    chords     => 0,
);

is $mtr->parse('Cb'), 'I', 'I';
is $mtr->parse('Db'), 'II', 'II';
is $mtr->parse('Eb'), 'iii', 'iii';
is $mtr->parse('F'), 'iv', 'iv';
is $mtr->parse('Gb'), 'V', 'V';
is $mtr->parse('Ab'), 'vi', 'vi';
is $mtr->parse('Bb'), 'vii', 'vii';

diag 'Db mixolydian';

$mtr = Music::ToRoman->new(
    scale_note => 'Db',
    scale_name => 'mixolydian',
    chords     => 0,
);

is $mtr->parse('Db'), 'I', 'I';
is $mtr->parse('Eb'), 'ii', 'ii';
is $mtr->parse('F'), 'iii', 'iii';
is $mtr->parse('Gb'), 'IV', 'IV';
is $mtr->parse('Ab'), 'v', 'v';
is $mtr->parse('Bb'), 'vi', 'vi';
is $mtr->parse('Cb'), 'VII', 'VII';

diag 'Eb aeolian';

$mtr = Music::ToRoman->new(
    scale_note => 'Eb',
    scale_name => 'aeolian',
    chords     => 0,
);

is $mtr->parse('Eb'), 'i', 'i';
is $mtr->parse('F'), 'ii', 'ii';
is $mtr->parse('Gb'), 'III', 'III';
is $mtr->parse('Ab'), 'iv', 'iv';
is $mtr->parse('Bb'), 'v', 'v';
is $mtr->parse('Cb'), 'VI', 'VI';
is $mtr->parse('Db'), 'VII', 'VII';

diag 'F locrian';

$mtr = Music::ToRoman->new(
    scale_note => 'F',
    scale_name => 'locrian',
    chords     => 0,
);

is $mtr->parse('F'), 'i', 'i';
is $mtr->parse('Gb'), 'II', 'II';
is $mtr->parse('Ab'), 'iii', 'iii';
is $mtr->parse('Bb'), 'iv', 'iv';
is $mtr->parse('Cb'), 'V', 'V';
is $mtr->parse('Db'), 'VI', 'VI';
is $mtr->parse('Eb'), 'vii', 'vii';

done_testing();
