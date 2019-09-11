#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::ToRoman';

diag 'D# chords';

my $mtr = Music::ToRoman->new( scale_note => 'D#' );
isa_ok $mtr, 'Music::ToRoman';

is $mtr->parse('D#'), 'I', 'I';
is $mtr->parse('D#sus4'), 'Isus4', 'Isus4';
is $mtr->parse('D# sus4'), 'I sus4', 'I sus4';
is $mtr->parse('D#add9'), 'Iadd9', 'Iadd9';
is $mtr->parse('D# add9'), 'I add9', 'I add9';
is $mtr->parse('D#Maj7'), 'Imaj7', 'Imaj7';
is $mtr->parse('D# Maj7'), 'I maj7', 'I maj7';
is $mtr->parse('D#+'), 'I+', 'I+';
is $mtr->parse('D# xyz'), 'I xyz', 'I xyz';
is $mtr->parse('D#5'), 'I5', 'I5';
is $mtr->parse('D#64'), 'I64', 'I64';
is $mtr->parse('Em'), 'bii', 'bii';
is $mtr->parse('E#m'), 'ii', 'ii';
is $mtr->parse('Gbm'), 'biii', 'biii';
is $mtr->parse('F#m'), 'biii', 'biii';
is $mtr->parse('F##m'), 'iii', 'iii';
is $mtr->parse('G#'), 'IV', 'IV';
is $mtr->parse('A'), 'bV', 'bV';
is $mtr->parse('A#'), 'V', 'V';
is $mtr->parse('A#7'), 'V7', 'V7';
is $mtr->parse('Bm'), 'bvi', 'bvi';
is $mtr->parse('B#m'), 'vi', 'vi';
is $mtr->parse('B#m7'), 'vi7', 'vi7';
is $mtr->parse('B#m7b5'), 'vi7b5', 'vi7b5';
is $mtr->parse('B#min7'), 'vimin7', 'vimin7';
is $mtr->parse('Dbm'), 'bvii', 'bvii';
is $mtr->parse('Dbo'), 'bviio', 'bviio';
is $mtr->parse('C##o'), 'viio', 'viio';
is $mtr->parse('C##dim'), 'viio', 'viio';
is $mtr->parse('C## dim'), 'vii o', 'vii o';

diag 'D#/X chords';

is $mtr->parse('D#/E'), 'I/bii', 'I/bii';
is $mtr->parse('D#/E#'), 'I/ii', 'I/ii';
is $mtr->parse('D#/Gb'), 'I/biii', 'I/biii';
is $mtr->parse('D#/F#'), 'I/biii', 'I/biii';
is $mtr->parse('D#/F##'), 'I/iii', 'I/iii';
is $mtr->parse('D#/G#'), 'I/IV', 'I/IV';
is $mtr->parse('D#/A'), 'I/bV', 'I/bV';
is $mtr->parse('D#/A#'), 'I/V', 'I/V';
is $mtr->parse('D#/B'), 'I/bvi', 'I/bvi';
is $mtr->parse('D#/B#'), 'I/vi', 'I/vi';
is $mtr->parse('D#/Db'), 'I/bvii', 'I/bvii';
is $mtr->parse('D#/C##'), 'I/vii', 'I/vii';
is $mtr->parse('D#m xyz/C##'), 'i xyz/vii', 'i xyz/vii';

diag 'E# dorian';

$mtr = Music::ToRoman->new(
    scale_note => 'E#',
    scale_name => 'dorian',
    chords     => 0,
);

is $mtr->parse('E#'), 'i', 'i';
is $mtr->parse('F##'), 'ii', 'ii';
is $mtr->parse('G#'), 'III', 'III';
is $mtr->parse('A#'), 'IV', 'IV';
is $mtr->parse('B#'), 'v', 'v';
is $mtr->parse('C##'), 'vi', 'vi';
is $mtr->parse('D#'), 'VII', 'VII';

diag 'F## phrygian';

$mtr = Music::ToRoman->new(
    scale_note  => 'F##',
    scale_name  => 'phrygian',
    major_tonic => 'D#',
    chords      => 0,
);

is $mtr->parse('F##'), 'i', 'i';
is $mtr->parse('G#'), 'II', 'II';
is $mtr->parse('A#'), 'III', 'III';
is $mtr->parse('B#'), 'iv', 'iv';
is $mtr->parse('C##'), 'v', 'v';
is $mtr->parse('D#'), 'VI', 'VI';
is $mtr->parse('E#'), 'vii', 'vii';

diag 'G# lydian';

$mtr = Music::ToRoman->new(
    scale_note => 'G#',
    scale_name => 'lydian',
    chords     => 0,
);

is $mtr->parse('G#'), 'I', 'I';
is $mtr->parse('A#'), 'II', 'II';
is $mtr->parse('B#'), 'iii', 'iii';
is $mtr->parse('C##'), 'iv', 'iv';
is $mtr->parse('D#'), 'V', 'V';
is $mtr->parse('E#'), 'vi', 'vi';
is $mtr->parse('F##'), 'vii', 'vii';

diag 'A# mixolydian';

$mtr = Music::ToRoman->new(
    scale_note => 'A#',
    scale_name => 'mixolydian',
    chords     => 0,
);

is $mtr->parse('A#'), 'I', 'I';
is $mtr->parse('B#'), 'ii', 'ii';
is $mtr->parse('C##'), 'iii', 'iii';
is $mtr->parse('D#'), 'IV', 'IV';
is $mtr->parse('E#'), 'v', 'v';
is $mtr->parse('F##'), 'vi', 'vi';
is $mtr->parse('G#'), 'VII', 'VII';

diag 'B# aeolian';

$mtr = Music::ToRoman->new(
    scale_note => 'B#',
    scale_name => 'aeolian',
    chords     => 0,
);

is $mtr->parse('B#'), 'i', 'i';
is $mtr->parse('C##'), 'ii', 'ii';
is $mtr->parse('D#'), 'III', 'III';
is $mtr->parse('E#'), 'iv', 'iv';
is $mtr->parse('F##'), 'v', 'v';
is $mtr->parse('G#'), 'VI', 'VI';
is $mtr->parse('A#'), 'VII', 'VII';

diag 'C## locrian';

$mtr = Music::ToRoman->new(
    scale_note  => 'C##',
    scale_name  => 'locrian',
    major_tonic => 'D#',
    chords      => 0,
);

is $mtr->parse('C##'), 'i', 'i';
is $mtr->parse('D#'), 'II', 'II';
is $mtr->parse('E#'), 'iii', 'iii';
is $mtr->parse('F##'), 'iv', 'iv';
is $mtr->parse('G#'), 'V', 'V';
is $mtr->parse('A#'), 'VI', 'VI';
is $mtr->parse('B#'), 'vii', 'vii';

diag 'Eb chords';

$mtr = Music::ToRoman->new( scale_note => 'Eb' );
isa_ok $mtr, 'Music::ToRoman';

is $mtr->parse('Eb'), 'I', 'I';
is $mtr->parse('Ebsus4'), 'Isus4', 'Isus4';
is $mtr->parse('Eb sus4'), 'I sus4', 'I sus4';
is $mtr->parse('Ebadd9'), 'Iadd9', 'Iadd9';
is $mtr->parse('Eb add9'), 'I add9', 'I add9';
is $mtr->parse('EbMaj7'), 'Imaj7', 'Imaj7';
is $mtr->parse('Eb Maj7'), 'I maj7', 'I maj7';
is $mtr->parse('Eb+'), 'I+', 'I+';
is $mtr->parse('Eb xyz'), 'I xyz', 'I xyz';
is $mtr->parse('Eb5'), 'I5', 'I5';
is $mtr->parse('Eb64'), 'I64', 'I64';
is $mtr->parse('Em'), 'bii', 'bii';
is $mtr->parse('Fm'), 'ii', 'ii';
is $mtr->parse('Gbm'), 'biii', 'biii';
is $mtr->parse('Gm'), 'iii', 'iii';
is $mtr->parse('Ab'), 'IV', 'IV';
is $mtr->parse('A'), 'bV', 'bV';
is $mtr->parse('Bb'), 'V', 'V';
is $mtr->parse('Bb7'), 'V7', 'V7';
is $mtr->parse('Bm'), 'bvi', 'bvi';
is $mtr->parse('Cm'), 'vi', 'vi';
is $mtr->parse('Cm7'), 'vi7', 'vi7';
is $mtr->parse('Cm7b5'), 'vi7b5', 'vi7b5';
is $mtr->parse('Cmin7'), 'vimin7', 'vimin7';
is $mtr->parse('Dbm'), 'bvii', 'bvii';
is $mtr->parse('Dbo'), 'bviio', 'bviio';
is $mtr->parse('Do'), 'viio', 'viio';
is $mtr->parse('Ddim'), 'viio', 'viio';
is $mtr->parse('D dim'), 'vii o', 'vii o';

diag 'Eb/X chords';

is $mtr->parse('Eb/E'), 'I/bii', 'I/bii';
is $mtr->parse('Eb/F'), 'I/ii', 'I/ii';
is $mtr->parse('Eb/Gb'), 'I/biii', 'I/biii';
is $mtr->parse('Eb/G'), 'I/iii', 'I/iii';
is $mtr->parse('Eb/Ab'), 'I/IV', 'I/IV';
is $mtr->parse('Eb/A'), 'I/bV', 'I/bV';
is $mtr->parse('Eb/Bb'), 'I/V', 'I/V';
is $mtr->parse('Eb/B'), 'I/bvi', 'I/bvi';
is $mtr->parse('Eb/C'), 'I/vi', 'I/vi';
is $mtr->parse('Eb/Db'), 'I/bvii', 'I/bvii';
is $mtr->parse('Eb/D'), 'I/vii', 'I/vii';
is $mtr->parse('Ebm xyz/D'), 'i xyz/vii', 'i xyz/vii';

diag 'F dorian';

$mtr = Music::ToRoman->new(
    scale_note => 'F',
    scale_name => 'dorian',
    chords     => 0,
);

is $mtr->parse('F'), 'i', 'i';
is $mtr->parse('G'), 'ii', 'ii';
is $mtr->parse('Ab'), 'III', 'III';
is $mtr->parse('Bb'), 'IV', 'IV';
is $mtr->parse('C'), 'v', 'v';
is $mtr->parse('D'), 'vi', 'vi';
is $mtr->parse('Eb'), 'VII', 'VII';

diag 'G phrygian';

$mtr = Music::ToRoman->new(
    scale_note => 'G',
    scale_name => 'phrygian',
    chords     => 0,
);

is $mtr->parse('G'), 'i', 'i';
is $mtr->parse('Ab'), 'II', 'II';
is $mtr->parse('Bb'), 'III', 'III';
is $mtr->parse('C'), 'iv', 'iv';
is $mtr->parse('D'), 'v', 'v';
is $mtr->parse('Eb'), 'VI', 'VI';
is $mtr->parse('F'), 'vii', 'vii';

diag 'Ab lydian';

$mtr = Music::ToRoman->new(
    scale_note => 'Ab',
    scale_name => 'lydian',
    chords     => 0,
);

is $mtr->parse('Ab'), 'I', 'I';
is $mtr->parse('Bb'), 'II', 'II';
is $mtr->parse('C'), 'iii', 'iii';
is $mtr->parse('D'), 'iv', 'iv';
is $mtr->parse('Eb'), 'V', 'V';
is $mtr->parse('F'), 'vi', 'vi';
is $mtr->parse('G'), 'vii', 'vii';

diag 'Bb mixolydian';

$mtr = Music::ToRoman->new(
    scale_note => 'Bb',
    scale_name => 'mixolydian',
    chords     => 0,
);

is $mtr->parse('Bb'), 'I', 'I';
is $mtr->parse('C'), 'ii', 'ii';
is $mtr->parse('D'), 'iii', 'iii';
is $mtr->parse('Eb'), 'IV', 'IV';
is $mtr->parse('F'), 'v', 'v';
is $mtr->parse('G'), 'vi', 'vi';
is $mtr->parse('Ab'), 'VII', 'VII';

diag 'C aeolian';

$mtr = Music::ToRoman->new(
    scale_note => 'C',
    scale_name => 'aeolian',
    chords     => 0,
);

is $mtr->parse('C'), 'i', 'i';
is $mtr->parse('D'), 'ii', 'ii';
is $mtr->parse('Eb'), 'III', 'III';
is $mtr->parse('F'), 'iv', 'iv';
is $mtr->parse('G'), 'v', 'v';
is $mtr->parse('Ab'), 'VI', 'VI';
is $mtr->parse('Bb'), 'VII', 'VII';

diag 'D locrian';

$mtr = Music::ToRoman->new(
    scale_note => 'D',
    scale_name => 'locrian',
    chords     => 0,
);

is $mtr->parse('D'), 'i', 'i';
is $mtr->parse('Eb'), 'II', 'II';
is $mtr->parse('F'), 'iii', 'iii';
is $mtr->parse('G'), 'iv', 'iv';
is $mtr->parse('Ab'), 'V', 'V';
is $mtr->parse('Bb'), 'VI', 'VI';
is $mtr->parse('C'), 'vii', 'vii';

done_testing();
