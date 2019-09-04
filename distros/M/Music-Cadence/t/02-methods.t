#!/usr/bin/env perl
use strict;
use warnings;
no warnings 'qw';

use Test::More;

use_ok 'Music::Cadence';

my $mc = Music::Cadence->new( seven => 1 );
isa_ok $mc, 'Music::Cadence';

my $chords = $mc->cadence;
is_deeply $chords, [ [qw/ G B D F /], [qw/ C E G A# C /] ], 'C7 0 perfect';

$chords = $mc->cadence(
    key    => 'C#',
    octave => 4,
    seven  => 1,
);
is_deeply $chords, [ [qw/ G#4 C4 D#4 F#4 /], [qw/ C#4 F4 G#4 B4 C#5 /] ], 'C#7 4 perfect';

$chords = $mc->cadence( type  => 'plagal' );
is_deeply $chords, [ [qw/ F A C D# /], [qw/ C E G A# /] ], 'C7 0 plagal';

$chords = $mc->cadence(
    key  => 'C#',
    type => 'plagal',
);
is_deeply $chords, [ [qw/ F# A# C# E /], [qw/ C# F G# B /] ], 'C#7 0 plagal';

$chords = $mc->cadence(
    type    => 'half',
    leading => 7,
);
is_deeply $chords, [ [qw/ B D F G# /], [qw/ G B D F /] ], 'C7 0 half 7';

$chords = $mc->cadence(
    type    => 'half',
    leading => 2,
);
is_deeply $chords, [ [qw/ D F A C /], [qw/ G B D F /] ], 'C7 0 half 2';

$chords = $mc->cadence(
    type      => 'half',
    leading   => 2,
    inversion => { 1 => 1 },
);
is_deeply $chords, [ [qw/ F A C D /], [qw/ G B D F /] ], 'C7 0 half 2 inversion 1-1';

$chords = $mc->cadence(
    key     => 'C#',
    type    => 'half',
    leading => 2,
);
is_deeply $chords, [ [qw/ D# F# A# C# /], [qw/ G# C D# F# /] ], 'C#7 0 half 2';

$chords = $mc->cadence(
    key     => 'D',
    scale   => 'dorian',
    type    => 'half',
    leading => 6,
);
is_deeply $chords, [ [qw/ B D F G# /], [qw/ A C E G /] ], 'D7 0 dorian half';

$chords = $mc->cadence(
    key     => 'E',
    scale   => 'phrygian',
    type    => 'half',
    leading => 5,
);
is_deeply $chords, [ [qw/ B D F G# /], [qw/ B D F G# /] ], 'E7 0 phrygian half';

$chords = $mc->cadence( type => 'deceptive' );
is_deeply $chords, [ [qw/ G B D F /], [qw/ A C E G /] ], 'C7 0 deceptive 1';

$chords = $mc->cadence(
    key       => 'C#',
    type      => 'deceptive',
    variation => 2,
);
is_deeply $chords, [ [qw/ G# C D# F# /], [qw/ F# A# C# E /] ], 'C#7 0 deceptive 2';

$chords = $mc->cadence( type => 'imperfect' );
is_deeply $chords, [ [qw/ G B D F /], [qw/ C E G A# /] ], 'C7 0 imperfect 1';

$chords = $mc->cadence(
    type      => 'imperfect',
    variation => 2,
);
is_deeply $chords, [ [qw/ B D F G# /], [qw/ C E G A# /] ], 'C7 0 imperfect 2';

$chords = $mc->cadence(
    type      => 'imperfect',
    inversion => { 1 => 1 },
);
is_deeply $chords, [ [qw/ B D F G /], [qw/ C E G A# /] ], 'C7 0 imperfect inversion 1-1';

$chords = $mc->cadence(
    type      => 'imperfect',
    inversion => { 1 => 1, 2 => 0 },
);
is_deeply $chords, [ [qw/ B D F G /], [qw/ C E G A# /] ], 'C7 0 imperfect inversion 1-1,2-0';

$chords = $mc->cadence(
    type      => 'imperfect',
    inversion => { 1 => 2 },
);
is_deeply $chords, [ [qw/ D F G B /], [qw/ C E G A# /] ], 'C7 0 imperfect inversion 1-2';

$chords = $mc->cadence(
    type      => 'imperfect',
    inversion => { 1 => 1, 2 => 1 },
);
is_deeply $chords, [ [qw/ B D F G /], [qw/ E G A# C /] ], 'C7 0 imperfect inversion 1-1,2-1';

$chords = $mc->cadence(
    octave    => 4,
    type      => 'imperfect',
    inversion => { 1 => 1, 2 => 1 },
);
is_deeply $chords, [ [qw/ B4 D4 F4 G5 /], [qw/ E4 G4 A#4 C5 /] ], 'C7 4 imperfect inversion 1-1,2-1';

$chords = $mc->cadence(
    key       => 'C#',
    octave    => 4,
    type      => 'imperfect',
    inversion => { 1 => 1, 2 => 1 },
);
is_deeply $chords, [ [qw/ C4 D#4 F#4 G#5 /], [qw/ F4 G#4 B4 C#5 /] ], 'C#7 4 imperfect inversion 1-1,2-1';

$chords = $mc->cadence(
    octave => 4,
    type   => 'evaded',
);
is_deeply $chords, [ [qw/ F4 G5 B5 D5 /], [qw/ E4 G4 A#4 C5 /] ], 'C7 4 evaded';

$chords = $mc->cadence(
    octave    => 4,
    type      => 'imperfect',
    inversion => { 1 => 3, 2 => 1 },
);
is_deeply $chords, [ [qw/ F4 G5 B5 D5 /], [qw/ E4 G4 A#4 C5 /] ], 'C7 4 imperfect inversion 1-3,2-1';

$chords = $mc->cadence(
    octave    => 4,
    type      => 'evaded',
    inversion => { 1 => 1, 2 => 2 },
);
is_deeply $chords, [ [qw/ B4 D4 F4 G5 /], [qw/ G4 A#4 C5 E5 /] ], 'C7 4 evaded inversion 1-1,2-2';

$mc = Music::Cadence->new(
    key    => 'C#',
    octave => 5,
    format => 'midi',
    seven  => 1,
);

$chords = $mc->cadence;
is_deeply $chords, [ [qw/ Gs5 C5 Ds5 Fs5 /], [qw/ Cs5 F5 Gs5 B5 Cs6 /] ], 'C#7 5 perfect midi';

$mc = Music::Cadence->new(
    octave => 4,
    format => 'midinum',
    seven  => 1,
);

$chords = $mc->cadence;
is_deeply $chords, [ [ 67, 71, 62, 65 ], [ 60, 64, 67, 70, 72 ] ], 'C7 4 perfect midinum';

$mc = Music::Cadence->new(
    format => 'midinum',
    seven  => 1,
);

$chords = $mc->cadence;
is_deeply $chords, [ [ 19, 23, 14, 17 ], [ 12, 16, 19, 22, 24 ] ], 'C7 0 perfect midinum';

$chords = $mc->cadence( octave => -1 );
is_deeply $chords, [ [ 7, 11, 2, 5 ], [ 0, 4, 7, 10, 12 ] ], 'C7 -1 perfect midinum';

done_testing();
