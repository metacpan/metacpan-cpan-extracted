#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::ToRoman';

diag 'F chords';

my $mtr = Music::ToRoman->new( scale_note => 'F' );
isa_ok $mtr, 'Music::ToRoman';

is $mtr->parse('F'), 'I', 'I';
is $mtr->parse('Fsus4'), 'Isus4', 'Isus4';
is $mtr->parse('F sus4'), 'I sus4', 'I sus4';
is $mtr->parse('Fadd9'), 'Iadd9', 'Iadd9';
is $mtr->parse('F add9'), 'I add9', 'I add9';
is $mtr->parse('FMaj7'), 'Imaj7', 'Imaj7';
is $mtr->parse('F Maj7'), 'I maj7', 'I maj7';
is $mtr->parse('F+'), 'I+', 'I+';
is $mtr->parse('F xyz'), 'I xyz', 'I xyz';
is $mtr->parse('F5'), 'I5', 'I5';
is $mtr->parse('F64'), 'I64', 'I64';
is $mtr->parse('Gbm'), 'bii', 'bii';
is $mtr->parse('Gm'), 'ii', 'ii';
is $mtr->parse('Abm'), 'biii', 'biii';
is $mtr->parse('Am'), 'iii', 'iii';
is $mtr->parse('Bb'), 'IV', 'IV';
is $mtr->parse('B'), 'bV', 'bV';
is $mtr->parse('C'), 'V', 'V';
is $mtr->parse('C7'), 'V7', 'V7';
is $mtr->parse('Dbm'), 'bvi', 'bvi';
is $mtr->parse('Dm'), 'vi', 'vi';
is $mtr->parse('Dm7'), 'vi7', 'vi7';
is $mtr->parse('Dm7b5'), 'vi7b5', 'vi7b5';
is $mtr->parse('Dmin7'), 'vimin7', 'vimin7';
is $mtr->parse('Ebm'), 'bvii', 'bvii';
is $mtr->parse('Ebo'), 'bviio', 'bviio';
is $mtr->parse('Eo'), 'viio', 'viio';
is $mtr->parse('Edim'), 'viio', 'viio';
is $mtr->parse('E dim'), 'vii o', 'vii o';

diag 'F/X chords';

is $mtr->parse('F/Gb'), 'I/bii', 'I/bii';
is $mtr->parse('F/G'), 'I/ii', 'I/ii';
is $mtr->parse('F/Ab'), 'I/biii', 'I/biii';
is $mtr->parse('F/A'), 'I/iii', 'I/iii';
is $mtr->parse('F/Bb'), 'I/IV', 'I/IV';
is $mtr->parse('F/B'), 'I/bV', 'I/bV';
is $mtr->parse('F/C'), 'I/V', 'I/V';
is $mtr->parse('F/Db'), 'I/bvi', 'I/bvi';
is $mtr->parse('F/D'), 'I/vi', 'I/vi';
is $mtr->parse('F/Eb'), 'I/bvii', 'I/bvii';
is $mtr->parse('F/E'), 'I/vii', 'I/vii';
is $mtr->parse('Fm xyz/E'), 'i xyz/vii', 'i xyz/vii';

diag 'G dorian';

$mtr = Music::ToRoman->new(
    scale_note => 'G',
    scale_name => 'dorian',
    chords     => 0,
);

is $mtr->parse('G'), 'i', 'i';
is $mtr->parse('A'), 'ii', 'ii';
is $mtr->parse('Bb'), 'III', 'III';
is $mtr->parse('C'), 'IV', 'IV';
is $mtr->parse('D'), 'v', 'v';
is $mtr->parse('E'), 'vi', 'vi';
is $mtr->parse('F'), 'VII', 'VII';

diag 'A phrygian';

$mtr = Music::ToRoman->new(
    scale_note => 'A',
    scale_name => 'phrygian',
    chords     => 0,
);

is $mtr->parse('A'), 'i', 'i';
is $mtr->parse('Bb'), 'II', 'II';
is $mtr->parse('C'), 'III', 'III';
is $mtr->parse('D'), 'iv', 'iv';
is $mtr->parse('E'), 'v', 'v';
is $mtr->parse('F'), 'VI', 'VI';
is $mtr->parse('G'), 'vii', 'vii';

diag 'Bb lydian';

$mtr = Music::ToRoman->new(
    scale_note => 'Bb',
    scale_name => 'lydian',
    chords     => 0,
);

is $mtr->parse('Bb'), 'I', 'I';
is $mtr->parse('C'), 'II', 'II';
is $mtr->parse('D'), 'iii', 'iii';
is $mtr->parse('E'), 'iv', 'iv';
is $mtr->parse('F'), 'V', 'V';
is $mtr->parse('G'), 'vi', 'vi';
is $mtr->parse('A'), 'vii', 'vii';

diag 'C mixolydian';

$mtr = Music::ToRoman->new(
    scale_note => 'C',
    scale_name => 'mixolydian',
    chords     => 0,
);

is $mtr->parse('C'), 'I', 'I';
is $mtr->parse('D'), 'ii', 'ii';
is $mtr->parse('E'), 'iii', 'iii';
is $mtr->parse('F'), 'IV', 'IV';
is $mtr->parse('G'), 'v', 'v';
is $mtr->parse('A'), 'vi', 'vi';
is $mtr->parse('Bb'), 'VII', 'VII';

diag 'D aeolian';

$mtr = Music::ToRoman->new(
    scale_note => 'D',
    scale_name => 'aeolian',
    chords     => 0,
);

is $mtr->parse('D'), 'i', 'i';
is $mtr->parse('E'), 'ii', 'ii';
is $mtr->parse('F'), 'III', 'III';
is $mtr->parse('G'), 'iv', 'iv';
is $mtr->parse('A'), 'v', 'v';
is $mtr->parse('Bb'), 'VI', 'VI';
is $mtr->parse('C'), 'VII', 'VII';

diag 'E locrian';

$mtr = Music::ToRoman->new(
    scale_note => 'E',
    scale_name => 'locrian',
    chords     => 0,
);

is $mtr->parse('E'), 'i', 'i';
is $mtr->parse('F'), 'II', 'II';
is $mtr->parse('G'), 'iii', 'iii';
is $mtr->parse('A'), 'iv', 'iv';
is $mtr->parse('Bb'), 'V', 'V';
is $mtr->parse('C'), 'VI', 'VI';
is $mtr->parse('D'), 'vii', 'vii';

done_testing();
