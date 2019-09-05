#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::ToRoman';

diag 'C chords';

my $mtr = Music::ToRoman->new;#( verbose => 1 );
isa_ok $mtr, 'Music::ToRoman';

is $mtr->parse('C'), 'I', 'I';
is $mtr->parse('CM'), 'I', 'I';
is $mtr->parse('C-'), 'i', 'i';
is $mtr->parse('Csus4'), 'Isus4', 'Isus4';
is $mtr->parse('C sus4'), 'I sus4', 'I sus4';
is $mtr->parse('Cadd9'), 'Iadd9', 'Iadd9';
is $mtr->parse('C add9'), 'I add9', 'I add9';
is $mtr->parse('CMaj7'), 'Imaj7', 'Imaj7';
is $mtr->parse('Cmaj7'), 'Imaj7', 'Imaj7';
is $mtr->parse('C Maj7'), 'I maj7', 'I maj7';
is $mtr->parse('C maj7'), 'I maj7', 'I maj7';
is $mtr->parse('C+'), 'I+', 'I+';
is $mtr->parse('C xyz'), 'I xyz', 'I xyz';
is $mtr->parse('C5'), 'I5', 'I5';
is $mtr->parse('C64'), 'I64', 'I64';
is $mtr->parse('Dbm'), 'bii', 'bii';
is $mtr->parse('Dm'), 'ii', 'ii';
is $mtr->parse('Ebm'), 'biii', 'biii';
is $mtr->parse('Em'), 'iii', 'iii';
is $mtr->parse('F'), 'IV', 'IV';
is $mtr->parse('Gb'), 'bV', 'bV';
is $mtr->parse('G'), 'V', 'V';
is $mtr->parse('G7'), 'V7', 'V7';
is $mtr->parse('Abm'), 'bvi', 'bvi';
is $mtr->parse('Am'), 'vi', 'vi';
is $mtr->parse('Am7'), 'vi7', 'vi7';
is $mtr->parse('Am7b5'), 'vi7b5', 'vi7b5';
is $mtr->parse('Amin7'), 'vimin7', 'vimin7';
is $mtr->parse('Bbo'), 'bviio', 'bviio';
is $mtr->parse('Bo'), 'viio', 'viio';
is $mtr->parse('Bdim'), 'viio', 'viio';
is $mtr->parse('B dim'), 'vii o', 'vii o';
SKIP: {
    skip 'U+25B3 works but is it needed?', 1;
    is $mtr->parse('B △7'), 'VII △7', 'VII △7';
};
SKIP: {
    skip 'U+00F8 does not mean diminished yet.', 1;
    is $mtr->parse('Bø'), 'viio', 'viio';
};

diag 'C/X chords';

is $mtr->parse('C/Db'), 'I/bii', 'I/bii';
is $mtr->parse('C/D'), 'I/ii', 'I/ii';
is $mtr->parse('C/Eb'), 'I/biii', 'I/biii';
is $mtr->parse('C/E'), 'I/iii', 'I/iii';
is $mtr->parse('C/F'), 'I/IV', 'I/IV';
is $mtr->parse('C/Gb'), 'I/bV', 'I/bV';
is $mtr->parse('C/G'), 'I/V', 'I/V';
is $mtr->parse('C/Ab'), 'I/bvi', 'I/bvi';
is $mtr->parse('C/A'), 'I/vi', 'I/vi';
is $mtr->parse('C/Bb'), 'I/bvii', 'I/bvii';
is $mtr->parse('C/B'), 'I/vii', 'I/vii';
is $mtr->parse('Cm xyz/B'), 'i xyz/vii', 'i xyz/vii';

diag 'D dorian';

$mtr = Music::ToRoman->new(
    scale_note => 'D',
    scale_name => 'dorian',
    chords     => 0,
);

is $mtr->parse('D'), 'i', 'i';
is $mtr->parse('E'), 'ii', 'ii';
is $mtr->parse('F'), 'III', 'III';
is $mtr->parse('G'), 'IV', 'IV';
is $mtr->parse('A'), 'v', 'v';
is $mtr->parse('B'), 'vi', 'vi';
is $mtr->parse('C'), 'VII', 'VII';

diag 'E phrygian';

$mtr = Music::ToRoman->new(
    scale_note => 'E',
    scale_name => 'phrygian',
    chords     => 0,
);

is $mtr->parse('E'), 'i', 'i';
is $mtr->parse('F'), 'II', 'II';
is $mtr->parse('G'), 'III', 'III';
is $mtr->parse('A'), 'iv', 'iv';
is $mtr->parse('B'), 'v', 'v';
is $mtr->parse('C'), 'VI', 'VI';
is $mtr->parse('D'), 'vii', 'vii';

diag 'F lydian';

$mtr = Music::ToRoman->new(
    scale_note => 'F',
    scale_name => 'lydian',
    chords     => 0,
);

is $mtr->parse('F'), 'I', 'I';
is $mtr->parse('G'), 'II', 'II';
is $mtr->parse('A'), 'iii', 'iii';
is $mtr->parse('B'), 'iv', 'iv';
is $mtr->parse('C'), 'V', 'V';
is $mtr->parse('D'), 'vi', 'vi';
is $mtr->parse('E'), 'vii', 'vii';

diag 'G mixolydian';

$mtr = Music::ToRoman->new(
    scale_note => 'G',
    scale_name => 'mixolydian',
    chords     => 0,
);

is $mtr->parse('G'), 'I', 'I';
is $mtr->parse('A'), 'ii', 'ii';
is $mtr->parse('B'), 'iii', 'iii';
is $mtr->parse('C'), 'IV', 'IV';
is $mtr->parse('D'), 'v', 'v';
is $mtr->parse('E'), 'vi', 'vi';
is $mtr->parse('F'), 'VII', 'VII';

diag 'A aeolian';

$mtr = Music::ToRoman->new(
    scale_note => 'A',
    scale_name => 'aeolian',
    chords     => 0,
);

is $mtr->parse('A'), 'i', 'i';
is $mtr->parse('B'), 'ii', 'ii';
is $mtr->parse('C'), 'III', 'III';
is $mtr->parse('D'), 'iv', 'iv';
is $mtr->parse('E'), 'v', 'v';
is $mtr->parse('F'), 'VI', 'VI';
is $mtr->parse('G'), 'VII', 'VII';

diag 'B locrian';

$mtr = Music::ToRoman->new(
    scale_note => 'B',
    scale_name => 'locrian',
    chords     => 0,
);

is $mtr->parse('B'), 'i', 'i';
is $mtr->parse('C'), 'II', 'II';
is $mtr->parse('D'), 'iii', 'iii';
is $mtr->parse('E'), 'iv', 'iv';
is $mtr->parse('F'), 'V', 'V';
is $mtr->parse('G'), 'VI', 'VI';
is $mtr->parse('A'), 'vii', 'vii';

done_testing();
