#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::ToRoman';

diag 'D chords';

my $mtr = Music::ToRoman->new( scale_note => 'D' );
isa_ok $mtr, 'Music::ToRoman';

is $mtr->parse('D'), 'I', 'I';
is $mtr->parse('Dsus4'), 'Isus4', 'Isus4';
is $mtr->parse('D sus4'), 'I sus4', 'I sus4';
is $mtr->parse('Dadd9'), 'Iadd9', 'Iadd9';
is $mtr->parse('D add9'), 'I add9', 'I add9';
is $mtr->parse('DMaj7'), 'Imaj7', 'Imaj7';
is $mtr->parse('D Maj7'), 'I maj7', 'I maj7';
is $mtr->parse('D+'), 'I+', 'I+';
is $mtr->parse('D xyz'), 'I xyz', 'I xyz';
is $mtr->parse('D5'), 'I5', 'I5';
is $mtr->parse('D64'), 'I64', 'I64';
is $mtr->parse('Ebm'), 'bii', 'bii';
is $mtr->parse('Em'), 'ii', 'ii';
is $mtr->parse('Fm'), 'biii', 'biii';
is $mtr->parse('F#m'), 'iii', 'iii';
is $mtr->parse('G'), 'IV', 'IV';
is $mtr->parse('Ab'), 'bV', 'bV';
is $mtr->parse('A'), 'V', 'V';
is $mtr->parse('A7'), 'V7', 'V7';
is $mtr->parse('Bbm'), 'bvi', 'bvi';
is $mtr->parse('Bm'), 'vi', 'vi';
is $mtr->parse('Cm'), 'bvii', 'bvii';
is $mtr->parse('Co'), 'bviio', 'bviio';
is $mtr->parse('C#o'), 'viio', 'viio';
is $mtr->parse('C#dim'), 'viio', 'viio';
is $mtr->parse('C# dim'), 'vii o', 'vii o';

diag 'D/X chords';

is $mtr->parse('D/Eb'), 'I/bii', 'I/bii';
is $mtr->parse('D/E'), 'I/ii', 'I/ii';
is $mtr->parse('D/F'), 'I/biii', 'I/biii';
is $mtr->parse('D/F#'), 'I/iii', 'I/iii';
is $mtr->parse('D/G'), 'I/IV', 'I/IV';
is $mtr->parse('D/Ab'), 'I/bV', 'I/bV';
is $mtr->parse('D/A'), 'I/V', 'I/V';
is $mtr->parse('D/Bb'), 'I/bvi', 'I/bvi';
is $mtr->parse('D/B'), 'I/vi', 'I/vi';
is $mtr->parse('D/C'), 'I/bvii', 'I/bvii';
is $mtr->parse('D/C#'), 'I/vii', 'I/vii';
is $mtr->parse('Dm xyz/C#'), 'i xyz/vii', 'i xyz/vii';

diag 'E dorian';

$mtr = Music::ToRoman->new(
    scale_note => 'E',
    scale_name => 'dorian',
    chords     => 0,
);

is $mtr->parse('E'), 'i', 'i';
is $mtr->parse('F#'), 'ii', 'ii';
is $mtr->parse('G'), 'III', 'III';
is $mtr->parse('A'), 'IV', 'IV';
is $mtr->parse('B'), 'v', 'v';
is $mtr->parse('C#'), 'vi', 'vi';
is $mtr->parse('D'), 'VII', 'VII';

diag 'F# phrygian';

$mtr = Music::ToRoman->new(
    scale_note => 'F#',
    scale_name => 'phrygian',
    chords     => 0,
);

is $mtr->parse('F#'), 'i', 'i';
is $mtr->parse('G'), 'II', 'II';
is $mtr->parse('A'), 'III', 'III';
is $mtr->parse('B'), 'iv', 'iv';
is $mtr->parse('C#'), 'v', 'v';
is $mtr->parse('D'), 'VI', 'VI';
is $mtr->parse('E'), 'vii', 'vii';

diag 'G lydian';

$mtr = Music::ToRoman->new(
    scale_note => 'G',
    scale_name => 'lydian',
    chords     => 0,
);

is $mtr->parse('G'), 'I', 'I';
is $mtr->parse('A'), 'II', 'II';
is $mtr->parse('B'), 'iii', 'iii';
is $mtr->parse('C#'), 'iv', 'iv';
is $mtr->parse('D'), 'V', 'V';
is $mtr->parse('E'), 'vi', 'vi';
is $mtr->parse('F#'), 'vii', 'vii';

diag 'A mixolydian';

$mtr = Music::ToRoman->new(
    scale_note => 'A',
    scale_name => 'mixolydian',
    chords     => 0,
);

is $mtr->parse('A'), 'I', 'I';
is $mtr->parse('B'), 'ii', 'ii';
is $mtr->parse('C#'), 'iii', 'iii';
is $mtr->parse('D'), 'IV', 'IV';
is $mtr->parse('E'), 'v', 'v';
is $mtr->parse('F#'), 'vi', 'vi';
is $mtr->parse('G'), 'VII', 'VII';

diag 'B aeolian';

$mtr = Music::ToRoman->new(
    scale_note => 'B',
    scale_name => 'aeolian',
    chords     => 0,
);

is $mtr->parse('B'), 'i', 'i';
is $mtr->parse('C#'), 'ii', 'ii';
is $mtr->parse('D'), 'III', 'III';
is $mtr->parse('E'), 'iv', 'iv';
is $mtr->parse('F#'), 'v', 'v';
is $mtr->parse('G'), 'VI', 'VI';
is $mtr->parse('A'), 'VII', 'VII';

diag 'C# locrian';

$mtr = Music::ToRoman->new(
    scale_note => 'C#',
    scale_name => 'locrian',
    chords     => 0,
);

is $mtr->parse('C#'), 'i', 'i';
is $mtr->parse('D'), 'II', 'II';
is $mtr->parse('E'), 'iii', 'iii';
is $mtr->parse('F#'), 'iv', 'iv';
is $mtr->parse('G'), 'V', 'V';
is $mtr->parse('A'), 'VI', 'VI';
is $mtr->parse('B'), 'vii', 'vii';

done_testing();
