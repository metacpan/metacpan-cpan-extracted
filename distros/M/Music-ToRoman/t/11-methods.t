#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::ToRoman';

diag 'A# chords';

my $mtr = Music::ToRoman->new( scale_note => 'A#' );
isa_ok $mtr, 'Music::ToRoman';

is $mtr->parse('A#'), 'I', 'I';
is $mtr->parse('A#sus4'), 'Isus4', 'Isus4';
is $mtr->parse('A# sus4'), 'I sus4', 'I sus4';
is $mtr->parse('A#add9'), 'Iadd9', 'Iadd9';
is $mtr->parse('A# add9'), 'I add9', 'I add9';
is $mtr->parse('A#Maj7'), 'Imaj7', 'Imaj7';
is $mtr->parse('A# Maj7'), 'I maj7', 'I maj7';
is $mtr->parse('A#+'), 'I+', 'I+';
is $mtr->parse('A# xyz'), 'I xyz', 'I xyz';
is $mtr->parse('A#5'), 'I5', 'I5';
is $mtr->parse('A#64'), 'I64', 'I64';
is $mtr->parse('Bm'), 'bii', 'bii';
is $mtr->parse('B#m'), 'ii', 'ii';
SKIP: {
    skip 'Dbm|C#m = biii not working', 2;
    is $mtr->parse('Dbm'), 'biii', 'biii';
    is $mtr->parse('C#m'), 'biii', 'biii';
};
is $mtr->parse('C##m'), 'iii', 'iii';
is $mtr->parse('D#'), 'IV', 'IV';
is $mtr->parse('E'), 'bV', 'bV';
is $mtr->parse('E#'), 'V', 'V';
is $mtr->parse('E#7'), 'V7', 'V7';
SKIP: {
    skip 'Gbm|F#m = bvi not working', 2;
    is $mtr->parse('Gbm'), 'bvi', 'bvi';
    is $mtr->parse('F#m'), 'bvi', 'bvi';
};
is $mtr->parse('F##m'), 'vi', 'vi';
is $mtr->parse('Abm'), 'bvii', 'bvii';
SKIP: {
    skip 'G#m = bvii not working', 1;
    is $mtr->parse('G#m'), 'bvii', 'bvii';
};
is $mtr->parse('Abo'), 'bviio', 'bviio';
SKIP: {
    skip 'G#o = bviio not working', 1;
    is $mtr->parse('G#o'), 'bviio', 'bviio';
};
is $mtr->parse('G##o'), 'viio', 'viio';
is $mtr->parse('G##dim'), 'viio', 'viio';
is $mtr->parse('G## dim'), 'vii o', 'vii o';

diag 'A#/X chords';

is $mtr->parse('A#/B'), 'I/bii', 'I/bii';
is $mtr->parse('A#/B#'), 'I/ii', 'I/ii';
SKIP: {
    skip 'A#/C#|Db = biii not working', 2;
    is $mtr->parse('A#/C#'), 'I/biii', 'I/biii';
    is $mtr->parse('A#/Db'), 'I/biii', 'I/biii';
};
is $mtr->parse('A#/C##'), 'I/iii', 'I/iii';
is $mtr->parse('A#/D#'), 'I/IV', 'I/IV';
is $mtr->parse('A#/E'), 'I/bV', 'I/bV';
is $mtr->parse('A#/E#'), 'I/V', 'I/V';
SKIP: {
    skip 'A#/Gb|F# = bvi not working', 2;
    is $mtr->parse('A#/Gb'), 'I/bvi', 'I/bvi';
    is $mtr->parse('A#/F#'), 'I/bvi', 'I/bvi';
};
is $mtr->parse('A#/F##'), 'I/vi', 'I/vi';
is $mtr->parse('A#/Ab'), 'I/bvii', 'I/bvii';
is $mtr->parse('A#/G##'), 'I/vii', 'I/vii';
is $mtr->parse('A#m xyz/G##'), 'i xyz/vii', 'i xyz/vii';

diag 'B# dorian';

$mtr = Music::ToRoman->new(
    scale_note => 'B#',
    scale_name => 'dorian',
    chords     => 0,
);

is $mtr->parse('B#'), 'i', 'i';
is $mtr->parse('C##'), 'ii', 'ii';
is $mtr->parse('D#'), 'III', 'III';
is $mtr->parse('E#'), 'IV', 'IV';
is $mtr->parse('F##'), 'v', 'v';
is $mtr->parse('G##'), 'vi', 'vi';
is $mtr->parse('A#'), 'VII', 'VII';

diag 'C## phrygian';

$mtr = Music::ToRoman->new(
    scale_note  => 'C##',
    scale_name  => 'phrygian',
    major_tonic => 'A#',
    chords      => 0,
);

is $mtr->parse('C##'), 'i', 'i';
is $mtr->parse('D#'), 'II', 'II';
is $mtr->parse('E#'), 'III', 'III';
is $mtr->parse('F##'), 'iv', 'iv';
is $mtr->parse('G##'), 'v', 'v';
is $mtr->parse('A#'), 'VI', 'VI';
is $mtr->parse('B#'), 'vii', 'vii';

diag 'D# lydian';

$mtr = Music::ToRoman->new(
    scale_note => 'D#',
    scale_name => 'lydian',
    chords     => 0,
);

is $mtr->parse('D#'), 'I', 'I';
is $mtr->parse('E#'), 'II', 'II';
is $mtr->parse('F##'), 'iii', 'iii';
is $mtr->parse('G##'), 'iv', 'iv';
is $mtr->parse('A#'), 'V', 'V';
is $mtr->parse('B#'), 'vi', 'vi';
is $mtr->parse('C##'), 'vii', 'vii';

diag 'E# mixolydian';

$mtr = Music::ToRoman->new(
    scale_note => 'E#',
    scale_name => 'mixolydian',
    chords     => 0,
);

is $mtr->parse('E#'), 'I', 'I';
is $mtr->parse('F##'), 'ii', 'ii';
is $mtr->parse('G##'), 'iii', 'iii';
is $mtr->parse('A#'), 'IV', 'IV';
is $mtr->parse('B#'), 'v', 'v';
is $mtr->parse('C##'), 'vi', 'vi';
is $mtr->parse('D#'), 'VII', 'VII';

diag 'F## aeolian';

$mtr = Music::ToRoman->new(
    scale_note  => 'F##',
    scale_name  => 'aeolian',
    major_tonic => 'A#',
    chords      => 0,
);

is $mtr->parse('F##'), 'i', 'i';
is $mtr->parse('G##'), 'ii', 'ii';
is $mtr->parse('A#'), 'III', 'III';
is $mtr->parse('B#'), 'iv', 'iv';
is $mtr->parse('C##'), 'v', 'v';
is $mtr->parse('D#'), 'VI', 'VI';
is $mtr->parse('E#'), 'VII', 'VII';

diag 'G## locrian';

$mtr = Music::ToRoman->new(
    scale_note  => 'G##',
    scale_name  => 'locrian',
    major_tonic => 'A#',
    chords      => 0,
);

is $mtr->parse('G##'), 'i', 'i';
is $mtr->parse('A#'), 'II', 'II';
is $mtr->parse('B#'), 'iii', 'iii';
is $mtr->parse('C##'), 'iv', 'iv';
is $mtr->parse('D#'), 'V', 'V';
is $mtr->parse('E#'), 'VI', 'VI';
is $mtr->parse('F##'), 'vii', 'vii';

diag 'Bb chords';

$mtr = Music::ToRoman->new( scale_note => 'Bb' );
isa_ok $mtr, 'Music::ToRoman';

is $mtr->parse('Bb'), 'I', 'I';
is $mtr->parse('Bbsus4'), 'Isus4', 'Isus4';
is $mtr->parse('Bb sus4'), 'I sus4', 'I sus4';
is $mtr->parse('Bbadd9'), 'Iadd9', 'Iadd9';
is $mtr->parse('Bb add9'), 'I add9', 'I add9';
is $mtr->parse('BbMaj7'), 'Imaj7', 'Imaj7';
is $mtr->parse('Bb Maj7'), 'I maj7', 'I maj7';
is $mtr->parse('Bb+'), 'I+', 'I+';
is $mtr->parse('Bb xyz'), 'I xyz', 'I xyz';
is $mtr->parse('Bb5'), 'I5', 'I5';
is $mtr->parse('Bb64'), 'I64', 'I64';
is $mtr->parse('Bm'), 'bii', 'bii';
is $mtr->parse('Cm'), 'ii', 'ii';
is $mtr->parse('Dbm'), 'biii', 'biii';
is $mtr->parse('Dm'), 'iii', 'iii';
is $mtr->parse('Eb'), 'IV', 'IV';
is $mtr->parse('E'), 'bV', 'bV';
is $mtr->parse('F'), 'V', 'V';
is $mtr->parse('F7'), 'V7', 'V7';
is $mtr->parse('Gbm'), 'bvi', 'bvi';
is $mtr->parse('Gm'), 'vi', 'vi';
is $mtr->parse('Abm'), 'bvii', 'bvii';
is $mtr->parse('Abo'), 'bviio', 'bviio';
is $mtr->parse('Ao'), 'viio', 'viio';
is $mtr->parse('Adim'), 'viio', 'viio';
is $mtr->parse('A dim'), 'vii o', 'vii o';

diag 'Bb/X chords';

is $mtr->parse('Bb/B'), 'I/bii', 'I/bii';
is $mtr->parse('Bb/C'), 'I/ii', 'I/ii';
is $mtr->parse('Bb/Db'), 'I/biii', 'I/biii';
is $mtr->parse('Bb/D'), 'I/iii', 'I/iii';
is $mtr->parse('Bb/Eb'), 'I/IV', 'I/IV';
is $mtr->parse('Bb/E'), 'I/bV', 'I/bV';
is $mtr->parse('Bb/F'), 'I/V', 'I/V';
is $mtr->parse('Bb/Gb'), 'I/bvi', 'I/bvi';
is $mtr->parse('Bb/G'), 'I/vi', 'I/vi';
is $mtr->parse('Bb/Ab'), 'I/bvii', 'I/bvii';
is $mtr->parse('Bb/A'), 'I/vii', 'I/vii';
is $mtr->parse('Bbm xyz/A'), 'i xyz/vii', 'i xyz/vii';

diag 'C dorian';

$mtr = Music::ToRoman->new(
    scale_note => 'C',
    scale_name => 'dorian',
    chords     => 0,
);

is $mtr->parse('C'), 'i', 'i';
is $mtr->parse('D'), 'ii', 'ii';
is $mtr->parse('Eb'), 'III', 'III';
is $mtr->parse('F'), 'IV', 'IV';
is $mtr->parse('G'), 'v', 'v';
is $mtr->parse('A'), 'vi', 'vi';
is $mtr->parse('Bb'), 'VII', 'VII';

diag 'D phrygian';

$mtr = Music::ToRoman->new(
    scale_note => 'D',
    scale_name => 'phrygian',
    chords     => 0,
);

is $mtr->parse('D'), 'i', 'i';
is $mtr->parse('Eb'), 'II', 'II';
is $mtr->parse('F'), 'III', 'III';
is $mtr->parse('G'), 'iv', 'iv';
is $mtr->parse('A'), 'v', 'v';
is $mtr->parse('Bb'), 'VI', 'VI';
is $mtr->parse('C'), 'vii', 'vii';

diag 'Eb lydian';

$mtr = Music::ToRoman->new(
    scale_note => 'Eb',
    scale_name => 'lydian',
    chords     => 0,
);

is $mtr->parse('Eb'), 'I', 'I';
is $mtr->parse('F'), 'II', 'II';
is $mtr->parse('G'), 'iii', 'iii';
is $mtr->parse('A'), 'iv', 'iv';
is $mtr->parse('Bb'), 'V', 'V';
is $mtr->parse('C'), 'vi', 'vi';
is $mtr->parse('D'), 'vii', 'vii';

diag 'F mixolydian';

$mtr = Music::ToRoman->new(
    scale_note => 'F',
    scale_name => 'mixolydian',
    chords     => 0,
);

is $mtr->parse('F'), 'I', 'I';
is $mtr->parse('G'), 'ii', 'ii';
is $mtr->parse('A'), 'iii', 'iii';
is $mtr->parse('Bb'), 'IV', 'IV';
is $mtr->parse('C'), 'v', 'v';
is $mtr->parse('D'), 'vi', 'vi';
is $mtr->parse('Eb'), 'VII', 'VII';

diag 'G aeolian';

$mtr = Music::ToRoman->new(
    scale_note => 'G',
    scale_name => 'aeolian',
    chords     => 0,
);

is $mtr->parse('G'), 'i', 'i';
is $mtr->parse('A'), 'ii', 'ii';
is $mtr->parse('Bb'), 'III', 'III';
is $mtr->parse('C'), 'iv', 'iv';
is $mtr->parse('D'), 'v', 'v';
is $mtr->parse('Eb'), 'VI', 'VI';
is $mtr->parse('F'), 'VII', 'VII';

diag 'A locrian';

$mtr = Music::ToRoman->new(
    scale_note => 'A',
    scale_name => 'locrian',
    chords     => 0,
);

is $mtr->parse('A'), 'i', 'i';
is $mtr->parse('Bb'), 'II', 'II';
is $mtr->parse('C'), 'iii', 'iii';
is $mtr->parse('D'), 'iv', 'iv';
is $mtr->parse('Eb'), 'V', 'V';
is $mtr->parse('F'), 'VI', 'VI';
is $mtr->parse('G'), 'vii', 'vii';

done_testing();
