#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::ToRoman';

diag 'C# chords';

my $mtr = Music::ToRoman->new( scale_note => 'C#' );
isa_ok $mtr, 'Music::ToRoman';

is $mtr->parse('C#'), 'I', 'I';
is $mtr->parse('C#sus4'), 'Isus4', 'Isus4';
is $mtr->parse('C# sus4'), 'I sus4', 'I sus4';
is $mtr->parse('C#add9'), 'Iadd9', 'Iadd9';
is $mtr->parse('C# add9'), 'I add9', 'I add9';
is $mtr->parse('C#Maj7'), 'Imaj7', 'Imaj7';
is $mtr->parse('C# Maj7'), 'I maj7', 'I maj7';
is $mtr->parse('C#+'), 'I+', 'I+';
is $mtr->parse('C# xyz'), 'I xyz', 'I xyz';
is $mtr->parse('C#5'), 'I5', 'I5';
is $mtr->parse('C#64'), 'I64', 'I64';
is $mtr->parse('Dm'), 'bii', 'bii';
is $mtr->parse('D#m'), 'ii', 'ii';
is $mtr->parse('Em'), 'biii', 'biii';
is $mtr->parse('E#m'), 'iii', 'iii';
is $mtr->parse('F#'), 'IV', 'IV';
is $mtr->parse('G'), 'bV', 'bV';
is $mtr->parse('G#'), 'V', 'V';
is $mtr->parse('G#7'), 'V7', 'V7';
is $mtr->parse('Am'), 'bvi', 'bvi';
is $mtr->parse('A#m'), 'vi', 'vi';
is $mtr->parse('Bm'), 'bvii', 'bvii';
is $mtr->parse('Bo'), 'bviio', 'bviio';
is $mtr->parse('B#o'), 'viio', 'viio';
is $mtr->parse('B#dim'), 'viio', 'viio';
is $mtr->parse('B# dim'), 'vii o', 'vii o';

diag 'C#/X chords';

is $mtr->parse('C#/D'), 'I/bii', 'I/bii';
is $mtr->parse('C#/D#'), 'I/ii', 'I/ii';
is $mtr->parse('C#/E'), 'I/biii', 'I/biii';
is $mtr->parse('C#/E#'), 'I/iii', 'I/iii';
is $mtr->parse('C#/F#'), 'I/IV', 'I/IV';
is $mtr->parse('C#/G'), 'I/bV', 'I/bV';
is $mtr->parse('C#/G#'), 'I/V', 'I/V';
is $mtr->parse('C#/A'), 'I/bvi', 'I/bvi';
is $mtr->parse('C#/A#'), 'I/vi', 'I/vi';
is $mtr->parse('C#/B'), 'I/bvii', 'I/bvii';
is $mtr->parse('C#/B#'), 'I/vii', 'I/vii';
is $mtr->parse('C#m xyz/B#'), 'i xyz/vii', 'i xyz/vii';

diag 'D# dorian';

$mtr = Music::ToRoman->new(
    scale_note => 'D#',
    scale_name => 'dorian',
    chords     => 0,
);

is $mtr->parse('D#'), 'i', 'i';
is $mtr->parse('E#'), 'ii', 'ii';
is $mtr->parse('F#'), 'III', 'III';
is $mtr->parse('G#'), 'IV', 'IV';
is $mtr->parse('A#'), 'v', 'v';
is $mtr->parse('B#'), 'vi', 'vi';
is $mtr->parse('C#'), 'VII', 'VII';

diag 'E# phrygian';

$mtr = Music::ToRoman->new(
    scale_note => 'E#',
    scale_name => 'phrygian',
    chords     => 0,
);

is $mtr->parse('E#'), 'i', 'i';
is $mtr->parse('F#'), 'II', 'II';
is $mtr->parse('G#'), 'III', 'III';
is $mtr->parse('A#'), 'iv', 'iv';
is $mtr->parse('B#'), 'v', 'v';
is $mtr->parse('C#'), 'VI', 'VI';
is $mtr->parse('D#'), 'vii', 'vii';

diag 'F# lydian';

$mtr = Music::ToRoman->new(
    scale_note => 'F#',
    scale_name => 'lydian',
    chords     => 0,
);

is $mtr->parse('F#'), 'I', 'I';
is $mtr->parse('G#'), 'II', 'II';
is $mtr->parse('A#'), 'iii', 'iii';
is $mtr->parse('B#'), 'iv', 'iv';
is $mtr->parse('C#'), 'V', 'V';
is $mtr->parse('D#'), 'vi', 'vi';
is $mtr->parse('E#'), 'vii', 'vii';

diag 'G# mixolydian';

$mtr = Music::ToRoman->new(
    scale_note => 'G#',
    scale_name => 'mixolydian',
    chords     => 0,
);

is $mtr->parse('G#'), 'I', 'I';
is $mtr->parse('A#'), 'ii', 'ii';
is $mtr->parse('B#'), 'iii', 'iii';
is $mtr->parse('C#'), 'IV', 'IV';
is $mtr->parse('D#'), 'v', 'v';
is $mtr->parse('E#'), 'vi', 'vi';
is $mtr->parse('F#'), 'VII', 'VII';

diag 'A# aeolian';

$mtr = Music::ToRoman->new(
    scale_note => 'A#',
    scale_name => 'aeolian',
    chords     => 0,
);

is $mtr->parse('A#'), 'i', 'i';
is $mtr->parse('B#'), 'ii', 'ii';
is $mtr->parse('C#'), 'III', 'III';
is $mtr->parse('D#'), 'iv', 'iv';
is $mtr->parse('E#'), 'v', 'v';
is $mtr->parse('F#'), 'VI', 'VI';
is $mtr->parse('G#'), 'VII', 'VII';

diag 'B# locrian';

$mtr = Music::ToRoman->new(
    scale_note => 'B#',
    scale_name => 'locrian',
    chords     => 0,
);

is $mtr->parse('B#'), 'i', 'i';
is $mtr->parse('C#'), 'II', 'II';
is $mtr->parse('D#'), 'iii', 'iii';
is $mtr->parse('E#'), 'iv', 'iv';
is $mtr->parse('F#'), 'V', 'V';
is $mtr->parse('G#'), 'VI', 'VI';
is $mtr->parse('A#'), 'vii', 'vii';

diag 'Db chords';

$mtr = Music::ToRoman->new( scale_note => 'Db' );
isa_ok $mtr, 'Music::ToRoman';

is $mtr->parse('Db'), 'I', 'I';
is $mtr->parse('Dbsus4'), 'Isus4', 'Isus4';
is $mtr->parse('Db sus4'), 'I sus4', 'I sus4';
is $mtr->parse('Dbadd9'), 'Iadd9', 'Iadd9';
is $mtr->parse('Db add9'), 'I add9', 'I add9';
is $mtr->parse('DbMaj7'), 'Imaj7', 'Imaj7';
is $mtr->parse('Db Maj7'), 'I maj7', 'I maj7';
is $mtr->parse('Db+'), 'I+', 'I+';
is $mtr->parse('Db xyz'), 'I xyz', 'I xyz';
is $mtr->parse('Db5'), 'I5', 'I5';
is $mtr->parse('Db64'), 'I64', 'I64';
is $mtr->parse('Dm'), 'bii', 'bii';
is $mtr->parse('Ebm'), 'ii', 'ii';
is $mtr->parse('Em'), 'biii', 'biii';
is $mtr->parse('Fm'), 'iii', 'iii';
is $mtr->parse('Gb'), 'IV', 'IV';
is $mtr->parse('G'), 'bV', 'bV';
is $mtr->parse('Ab'), 'V', 'V';
is $mtr->parse('Ab7'), 'V7', 'V7';
is $mtr->parse('Am'), 'bvi', 'bvi';
is $mtr->parse('Bbm'), 'vi', 'vi';
is $mtr->parse('Bm'), 'bvii', 'bvii';
is $mtr->parse('Bo'), 'bviio', 'bviio';
is $mtr->parse('Co'), 'viio', 'viio';
is $mtr->parse('Cdim'), 'viio', 'viio';
is $mtr->parse('C dim'), 'vii o', 'vii o';

diag 'Db/X chords';

is $mtr->parse('Db/D'), 'I/bii', 'I/bii';
is $mtr->parse('Db/Eb'), 'I/ii', 'I/ii';
is $mtr->parse('Db/E'), 'I/biii', 'I/biii';
is $mtr->parse('Db/F'), 'I/iii', 'I/iii';
is $mtr->parse('Db/Gb'), 'I/IV', 'I/IV';
is $mtr->parse('Db/G'), 'I/bV', 'I/bV';
is $mtr->parse('Db/Ab'), 'I/V', 'I/V';
is $mtr->parse('Db/A'), 'I/bvi', 'I/bvi';
is $mtr->parse('Db/Bb'), 'I/vi', 'I/vi';
is $mtr->parse('Db/B'), 'I/bvii', 'I/bvii';
is $mtr->parse('Db/C'), 'I/vii', 'I/vii';
is $mtr->parse('Dbm xyz/C'), 'i xyz/vii', 'i xyz/vii';

diag 'Eb dorian';

$mtr = Music::ToRoman->new(
    scale_note => 'Eb',
    scale_name => 'dorian',
    chords     => 0,
);

is $mtr->parse('Eb'), 'i', 'i';
is $mtr->parse('F'), 'ii', 'ii';
is $mtr->parse('Gb'), 'III', 'III';
is $mtr->parse('Ab'), 'IV', 'IV';
is $mtr->parse('Bb'), 'v', 'v';
is $mtr->parse('C'), 'vi', 'vi';
is $mtr->parse('Db'), 'VII', 'VII';

diag 'F phrygian';

$mtr = Music::ToRoman->new(
    scale_note => 'F',
    scale_name => 'phrygian',
    chords     => 0,
);

is $mtr->parse('F'), 'i', 'i';
is $mtr->parse('Gb'), 'II', 'II';
is $mtr->parse('Ab'), 'III', 'III';
is $mtr->parse('Bb'), 'iv', 'iv';
is $mtr->parse('C'), 'v', 'v';
is $mtr->parse('Db'), 'VI', 'VI';
is $mtr->parse('Eb'), 'vii', 'vii';

diag 'Gb lydian';

$mtr = Music::ToRoman->new(
    scale_note => 'Gb',
    scale_name => 'lydian',
    chords     => 0,
);

is $mtr->parse('Gb'), 'I', 'I';
is $mtr->parse('Ab'), 'II', 'II';
is $mtr->parse('Bb'), 'iii', 'iii';
is $mtr->parse('C'), 'iv', 'iv';
is $mtr->parse('Db'), 'V', 'V';
is $mtr->parse('Eb'), 'vi', 'vi';
is $mtr->parse('F'), 'vii', 'vii';

diag 'Ab mixolydian';

$mtr = Music::ToRoman->new(
    scale_note => 'Ab',
    scale_name => 'mixolydian',
    chords     => 0,
);

is $mtr->parse('Ab'), 'I', 'I';
is $mtr->parse('Bb'), 'ii', 'ii';
is $mtr->parse('C'), 'iii', 'iii';
is $mtr->parse('Db'), 'IV', 'IV';
is $mtr->parse('Eb'), 'v', 'v';
is $mtr->parse('F'), 'vi', 'vi';
is $mtr->parse('Gb'), 'VII', 'VII';

diag 'Bb aeolian';

$mtr = Music::ToRoman->new(
    scale_note => 'Bb',
    scale_name => 'aeolian',
    chords     => 0,
);

is $mtr->parse('Bb'), 'i', 'i';
is $mtr->parse('C'), 'ii', 'ii';
is $mtr->parse('Db'), 'III', 'III';
is $mtr->parse('Eb'), 'iv', 'iv';
is $mtr->parse('F'), 'v', 'v';
is $mtr->parse('Gb'), 'VI', 'VI';
is $mtr->parse('Ab'), 'VII', 'VII';

diag 'C locrian';

$mtr = Music::ToRoman->new(
    scale_note => 'C',
    scale_name => 'locrian',
    chords     => 0,
);

is $mtr->parse('C'), 'i', 'i';
is $mtr->parse('Db'), 'II', 'II';
is $mtr->parse('Eb'), 'iii', 'iii';
is $mtr->parse('F'), 'iv', 'iv';
is $mtr->parse('Gb'), 'V', 'V';
is $mtr->parse('Ab'), 'VI', 'VI';
is $mtr->parse('Bb'), 'vii', 'vii';

done_testing();
