#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::ToRoman';

diag 'G# chords';

my $mtr = Music::ToRoman->new( scale_note => 'G#' );
isa_ok $mtr, 'Music::ToRoman';

is $mtr->parse('G#'), 'I', 'I';
is $mtr->parse('G#sus4'), 'Isus4', 'Isus4';
is $mtr->parse('G# sus4'), 'I sus4', 'I sus4';
is $mtr->parse('G#add9'), 'Iadd9', 'Iadd9';
is $mtr->parse('G# add9'), 'I add9', 'I add9';
is $mtr->parse('G#Maj7'), 'Imaj7', 'Imaj7';
is $mtr->parse('G# Maj7'), 'I maj7', 'I maj7';
is $mtr->parse('G#+'), 'I+', 'I+';
is $mtr->parse('G# xyz'), 'I xyz', 'I xyz';
is $mtr->parse('G#5'), 'I5', 'I5';
is $mtr->parse('G#64'), 'I64', 'I64';
is $mtr->parse('Am'), 'bii', 'bii';
is $mtr->parse('A#m'), 'ii', 'ii';
is $mtr->parse('Bm'), 'biii', 'biii';
is $mtr->parse('B#m'), 'iii', 'iii';
is $mtr->parse('C#'), 'IV', 'IV';
is $mtr->parse('D'), 'bV', 'bV';
is $mtr->parse('D#'), 'V', 'V';
is $mtr->parse('D#7'), 'V7', 'V7';
is $mtr->parse('Em'), 'bvi', 'bvi';
is $mtr->parse('E#m'), 'vi', 'vi';
is $mtr->parse('Gbm'), 'bvii', 'bvii';
is $mtr->parse('Gbo'), 'bviio', 'bviio';
is $mtr->parse('F##o'), 'viio', 'viio';
is $mtr->parse('F##dim'), 'viio', 'viio';
is $mtr->parse('F## dim'), 'vii o', 'vii o';

diag 'G#/X chords';

is $mtr->parse('G#/A'), 'I/bii', 'I/bii';
is $mtr->parse('G#/A#'), 'I/ii', 'I/ii';
is $mtr->parse('G#/B'), 'I/biii', 'I/biii';
is $mtr->parse('G#/B#'), 'I/iii', 'I/iii';
is $mtr->parse('G#/C#'), 'I/IV', 'I/IV';
is $mtr->parse('G#/D'), 'I/bV', 'I/bV';
is $mtr->parse('G#/D#'), 'I/V', 'I/V';
is $mtr->parse('G#/E'), 'I/bvi', 'I/bvi';
is $mtr->parse('G#/E#'), 'I/vi', 'I/vi';
is $mtr->parse('G#/Gb'), 'I/bvii', 'I/bvii';
is $mtr->parse('G#/F##'), 'I/vii', 'I/vii';
is $mtr->parse('G#m xyz/F##'), 'i xyz/vii', 'i xyz/vii';

diag 'A# dorian';

$mtr = Music::ToRoman->new(
    scale_note => 'A#',
    scale_name => 'dorian',
    chords     => 0,
);

is $mtr->parse('A#'), 'i', 'i';
is $mtr->parse('B#'), 'ii', 'ii';
is $mtr->parse('C#'), 'III', 'III';
is $mtr->parse('D#'), 'IV', 'IV';
is $mtr->parse('E#'), 'v', 'v';
is $mtr->parse('F##'), 'vi', 'vi';
is $mtr->parse('G#'), 'VII', 'VII';

diag 'B# phrygian';

$mtr = Music::ToRoman->new(
    scale_note => 'B#',
    scale_name => 'phrygian',
    chords     => 0,
);

is $mtr->parse('B#'), 'i', 'i';
is $mtr->parse('C#'), 'II', 'II';
is $mtr->parse('D#'), 'III', 'III';
is $mtr->parse('E#'), 'iv', 'iv';
is $mtr->parse('F##'), 'v', 'v';
is $mtr->parse('G#'), 'VI', 'VI';
is $mtr->parse('A#'), 'vii', 'vii';

diag 'C# lydian';

$mtr = Music::ToRoman->new(
    scale_note => 'C#',
    scale_name => 'lydian',
    chords     => 0,
);

is $mtr->parse('C#'), 'I', 'I';
is $mtr->parse('D#'), 'II', 'II';
is $mtr->parse('E#'), 'iii', 'iii';
is $mtr->parse('F##'), 'iv', 'iv';
is $mtr->parse('G#'), 'V', 'V';
is $mtr->parse('A#'), 'vi', 'vi';
is $mtr->parse('B#'), 'vii', 'vii';

diag 'D# mixolydian';

$mtr = Music::ToRoman->new(
    scale_note => 'D#',
    scale_name => 'mixolydian',
    chords     => 0,
);

is $mtr->parse('D#'), 'I', 'I';
is $mtr->parse('E#'), 'ii', 'ii';
is $mtr->parse('F##'), 'iii', 'iii';
is $mtr->parse('G#'), 'IV', 'IV';
is $mtr->parse('A#'), 'v', 'v';
is $mtr->parse('B#'), 'vi', 'vi';
is $mtr->parse('C#'), 'VII', 'VII';

diag 'E# aeolian';

$mtr = Music::ToRoman->new(
    scale_note => 'E#',
    scale_name => 'aeolian',
    chords     => 0,
);

is $mtr->parse('E#'), 'i', 'i';
is $mtr->parse('F##'), 'ii', 'ii';
is $mtr->parse('G#'), 'III', 'III';
is $mtr->parse('A#'), 'iv', 'iv';
is $mtr->parse('B#'), 'v', 'v';
is $mtr->parse('C#'), 'VI', 'VI';
is $mtr->parse('D#'), 'VII', 'VII';

diag 'F## locrian';

$mtr = Music::ToRoman->new(
    scale_note  => 'F##',
    scale_name  => 'locrian',
    major_tonic => 'G#',
    chords      => 0,
);

is $mtr->parse('F##'), 'i', 'i';
is $mtr->parse('G#'), 'II', 'II';
is $mtr->parse('A#'), 'iii', 'iii';
is $mtr->parse('B#'), 'iv', 'iv';
is $mtr->parse('C#'), 'V', 'V';
is $mtr->parse('D#'), 'VI', 'VI';
is $mtr->parse('E#'), 'vii', 'vii';

diag 'Ab chords';

$mtr = Music::ToRoman->new( scale_note => 'Ab' );
isa_ok $mtr, 'Music::ToRoman';

is $mtr->parse('Ab'), 'I', 'I';
is $mtr->parse('Absus4'), 'Isus4', 'Isus4';
is $mtr->parse('Ab sus4'), 'I sus4', 'I sus4';
is $mtr->parse('Abadd9'), 'Iadd9', 'Iadd9';
is $mtr->parse('Ab add9'), 'I add9', 'I add9';
is $mtr->parse('AbMaj7'), 'Imaj7', 'Imaj7';
is $mtr->parse('Ab Maj7'), 'I maj7', 'I maj7';
is $mtr->parse('Ab+'), 'I+', 'I+';
is $mtr->parse('Ab xyz'), 'I xyz', 'I xyz';
is $mtr->parse('Ab5'), 'I5', 'I5';
is $mtr->parse('Ab64'), 'I64', 'I64';
is $mtr->parse('Am'), 'bii', 'bii';
is $mtr->parse('Bbm'), 'ii', 'ii';
is $mtr->parse('Bm'), 'biii', 'biii';
is $mtr->parse('Cm'), 'iii', 'iii';
is $mtr->parse('Db'), 'IV', 'IV';
is $mtr->parse('D'), 'bV', 'bV';
is $mtr->parse('Eb'), 'V', 'V';
is $mtr->parse('Eb7'), 'V7', 'V7';
is $mtr->parse('Em'), 'bvi', 'bvi';
is $mtr->parse('Fm'), 'vi', 'vi';
is $mtr->parse('Gbm'), 'bvii', 'bvii';
is $mtr->parse('Gbo'), 'bviio', 'bviio';
is $mtr->parse('Go'), 'viio', 'viio';
is $mtr->parse('Gdim'), 'viio', 'viio';
is $mtr->parse('G dim'), 'vii o', 'vii o';

diag 'Ab/X chords';

is $mtr->parse('Ab/A'), 'I/bii', 'I/bii';
is $mtr->parse('Ab/Bb'), 'I/ii', 'I/ii';
is $mtr->parse('Ab/B'), 'I/biii', 'I/biii';
is $mtr->parse('Ab/C'), 'I/iii', 'I/iii';
is $mtr->parse('Ab/Db'), 'I/IV', 'I/IV';
is $mtr->parse('Ab/D'), 'I/bV', 'I/bV';
is $mtr->parse('Ab/Eb'), 'I/V', 'I/V';
is $mtr->parse('Ab/E'), 'I/bvi', 'I/bvi';
is $mtr->parse('Ab/F'), 'I/vi', 'I/vi';
is $mtr->parse('Ab/Gb'), 'I/bvii', 'I/bvii';
is $mtr->parse('Ab/G'), 'I/vii', 'I/vii';
is $mtr->parse('Abm xyz/G'), 'i xyz/vii', 'i xyz/vii';

diag 'Bb dorian';

$mtr = Music::ToRoman->new(
    scale_note => 'Bb',
    scale_name => 'dorian',
    chords     => 0,
);

is $mtr->parse('Bb'), 'i', 'i';
is $mtr->parse('C'), 'ii', 'ii';
is $mtr->parse('Db'), 'III', 'III';
is $mtr->parse('Eb'), 'IV', 'IV';
is $mtr->parse('F'), 'v', 'v';
is $mtr->parse('G'), 'vi', 'vi';
is $mtr->parse('Ab'), 'VII', 'VII';

diag 'C phrygian';

$mtr = Music::ToRoman->new(
    scale_note => 'C',
    scale_name => 'phrygian',
    chords     => 0,
);

is $mtr->parse('C'), 'i', 'i';
is $mtr->parse('Db'), 'II', 'II';
is $mtr->parse('Eb'), 'III', 'III';
is $mtr->parse('F'), 'iv', 'iv';
is $mtr->parse('G'), 'v', 'v';
is $mtr->parse('Ab'), 'VI', 'VI';
is $mtr->parse('Bb'), 'vii', 'vii';

diag 'Db lydian';

$mtr = Music::ToRoman->new(
    scale_note => 'Db',
    scale_name => 'lydian',
    chords     => 0,
);

is $mtr->parse('Db'), 'I', 'I';
is $mtr->parse('Eb'), 'II', 'II';
is $mtr->parse('F'), 'iii', 'iii';
is $mtr->parse('G'), 'iv', 'iv';
is $mtr->parse('Ab'), 'V', 'V';
is $mtr->parse('Bb'), 'vi', 'vi';
is $mtr->parse('C'), 'vii', 'vii';

diag 'Eb mixolydian';

$mtr = Music::ToRoman->new(
    scale_note => 'Eb',
    scale_name => 'mixolydian',
    chords     => 0,
);

is $mtr->parse('Eb'), 'I', 'I';
is $mtr->parse('F'), 'ii', 'ii';
is $mtr->parse('G'), 'iii', 'iii';
is $mtr->parse('Ab'), 'IV', 'IV';
is $mtr->parse('Bb'), 'v', 'v';
is $mtr->parse('C'), 'vi', 'vi';
is $mtr->parse('Db'), 'VII', 'VII';

diag 'F aeolian';

$mtr = Music::ToRoman->new(
    scale_note => 'F',
    scale_name => 'aeolian',
    chords     => 0,
);

is $mtr->parse('F'), 'i', 'i';
is $mtr->parse('G'), 'ii', 'ii';
is $mtr->parse('Ab'), 'III', 'III';
is $mtr->parse('Bb'), 'iv', 'iv';
is $mtr->parse('C'), 'v', 'v';
is $mtr->parse('Db'), 'VI', 'VI';
is $mtr->parse('Eb'), 'VII', 'VII';

diag 'G locrian';

$mtr = Music::ToRoman->new(
    scale_note => 'G',
    scale_name => 'locrian',
    chords     => 0,
);

is $mtr->parse('G'), 'i', 'i';
is $mtr->parse('Ab'), 'II', 'II';
is $mtr->parse('Bb'), 'iii', 'iii';
is $mtr->parse('C'), 'iv', 'iv';
is $mtr->parse('Db'), 'V', 'V';
is $mtr->parse('Eb'), 'VI', 'VI';
is $mtr->parse('F'), 'vii', 'vii';

done_testing();
