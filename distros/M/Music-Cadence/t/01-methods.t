#!/usr/bin/env perl
use strict;
use warnings;
no warnings 'qw';

use Test::More;
use Test::Exception;

use_ok 'Music::Cadence';

my $mc = Music::Cadence->new;
isa_ok $mc, 'Music::Cadence';

is $mc->key, 'C', 'default key';
is $mc->scale, 'major', 'default scale';
is $mc->octave, 0, 'default octave';
is $mc->format, 'isobase', 'default format';

dies_ok { $mc->cadence( key => 'X' ) } 'unknown key';

throws_ok { $mc->cadence( type => 'foo' ) }
    qr/unknown cadence/, 'unknown cadence';

throws_ok { $mc->cadence( scale => 'foo' ) }
    qr/unknown scale/, 'unknown scale';

throws_ok { $mc->cadence( leading => 666 ) }
    qr/unknown leader/, 'unknown leader';

$mc = Music::Cadence->new( format => 'foo' );
throws_ok { $mc->cadence }
    qr/unknown format/, 'unknown format';

$mc = Music::Cadence->new;

my $chords = $mc->cadence;
is_deeply $chords, [ [qw/ G B D /], [qw/ C E G C /] ], 'C 0 perfect';

$chords = $mc->cadence(
    key    => 'C#',
    octave => 4,
);
is_deeply $chords, [ [qw/ G#4 C4 D#4 /], [qw/ C#4 F4 G#4 C#5 /] ], 'C# 4 perfect';

$chords = $mc->cadence( type => 'plagal' );
is_deeply $chords, [ [qw/ F A C /], [qw/ C E G /] ], 'C 0 plagal';

$chords = $mc->cadence(
    key  => 'C#',
    type => 'plagal',
);
is_deeply $chords, [ [qw/ F# A# C# /], [qw/ C# F G# /] ], 'C# 0 plagal';

$chords = $mc->cadence(
    type    => 'half',
    leading => 7,
);
is_deeply $chords, [ [qw/ B D F /], [qw/ G B D /] ], 'C 0 half 7';

$chords = $mc->cadence(
    type    => 'half',
    leading => 2,
);
is_deeply $chords, [ [qw/ D F A /], [qw/ G B D /] ], 'C 0 half 2';

$chords = $mc->cadence(
    type      => 'half',
    leading   => 2,
    inversion => { 1 => 1 },
);
is_deeply $chords, [ [qw/ F A D /], [qw/ G B D /] ], 'C 0 half 2 inversion 1-1';

$chords = $mc->cadence(
    key     => 'C#',
    type    => 'half',
    leading => 2,
);
is_deeply $chords, [ [qw/ D# F# A# /], [qw/ G# C D# /] ], 'C# 0 half 2';

$chords = $mc->cadence(
    key     => 'D',
    scale   => 'dorian',
    type    => 'half',
    leading => 6,
);
is_deeply $chords, [ [qw/ B D F /], [qw/ A C E /] ], 'D 0 dorian half';

$chords = $mc->cadence(
    key     => 'D',
    scale   => 'dorian',
    type    => 'half',
    leading => 6,
    picardy => 1,
);
is_deeply $chords, [ [qw/ B D F /], [qw/ A C# E /] ], 'D 0 dorian half picardy';

$chords = $mc->cadence(
    key     => 'E',
    scale   => 'phrygian',
    type    => 'half',
    leading => 5,
);
is_deeply $chords, [ [qw/ B D F /], [qw/ B D F /] ], 'E 0 phrygian half';

$chords = $mc->cadence( type => 'deceptive' );
is_deeply $chords, [ [qw/ G B D /], [qw/ A C E /] ], 'C 0 deceptive 1';

$chords = $mc->cadence(
    key       => 'C#',
    type      => 'deceptive',
    variation => 2,
);
is_deeply $chords, [ [qw/ G# C D# /], [qw/ F# A# C# /] ], 'C# 0 deceptive 2';

$mc = Music::Cadence->new(
    key    => 'C#',
    octave => 5,
    format => 'midi',
);

$chords = $mc->cadence;
is_deeply $chords, [ [qw/ Gs5 C5 Ds5 /], [qw/ Cs5 F5 Gs5 Cs6 /] ], 'C# 5 perfect midi';

$mc = Music::Cadence->new(
    octave => 4,
    format => 'midinum',
);

$chords = $mc->cadence;
is_deeply $chords, [ [ 67, 71, 62 ], [ 60, 64, 67, 72 ] ], 'C 4 perfect midinum';

$mc = Music::Cadence->new(
    octave => 0,
    format => 'midinum',
);

$chords = $mc->cadence;
is_deeply $chords, [ [ 19, 23, 14 ], [ 12, 16, 19, 24 ] ], 'C 0 perfect midinum';

$mc = Music::Cadence->new(
    octave => -1,
    format => 'midinum',
);

$chords = $mc->cadence;
is_deeply $chords, [ [ 7, 11, 2 ], [ 0, 4, 7, 12 ] ], 'C -1 perfect midinum';

$mc = Music::Cadence->new;

$chords = $mc->cadence( type => 'imperfect' );
is_deeply $chords, [ [qw/ G B D /], [qw/ C E G /] ], 'C 0 imperfect 1';

$chords = $mc->cadence(
    type      => 'imperfect',
    variation => 2,
);
is_deeply $chords, [ [qw/ B D F /], [qw/ C E G /] ], 'C 0 imperfect 2';

$chords = $mc->cadence(
    type      => 'imperfect',
    inversion => { 1 => 1 },
);
is_deeply $chords, [ [qw/ B D G /], [qw/ C E G /] ], 'C 0 imperfect inversion 1-1';

$chords = $mc->cadence(
    type      => 'imperfect',
    inversion => { 1 => 1, 2 => 0 },
);
is_deeply $chords, [ [qw/ B D G /], [qw/ C E G /] ], 'C 0 imperfect inversion 1-1,2-0';

$chords = $mc->cadence(
    type      => 'imperfect',
    inversion => { 1 => 2 },
);
is_deeply $chords, [ [qw/ D G B /], [qw/ C E G /] ], 'C 0 imperfect inversion 1-2';

$chords = $mc->cadence(
    type      => 'imperfect',
    inversion => { 1 => 1, 2 => 1 },
);
is_deeply $chords, [ [qw/ B D G /], [qw/ E G C /] ], 'C 0 imperfect inversion 1-1,2-1';

$chords = $mc->cadence(
    octave    => 4,
    type      => 'imperfect',
    inversion => { 1 => 1, 2 => 1 },
);
is_deeply $chords, [ [qw/ B4 D4 G5 /], [qw/ E4 G4 C5 /] ], 'C 4 imperfect inversion 1-1,2-1';

$chords = $mc->cadence(
    key       => 'C#',
    octave    => 4,
    type      => 'imperfect',
    inversion => { 1 => 1, 2 => 1 },
);
is_deeply $chords, [ [qw/ C4 D#4 G#5 /], [qw/ F4 G#4 C#5 /] ], 'C# 4 imperfect inversion 1-1,2-1';

$mc = Music::Cadence->new( format => 'midi' );

$chords = $mc->cadence(
    key       => 'C#',
    octave    => 4,
    type      => 'imperfect',
    inversion => { 1 => 1, 2 => 1 },
);
is_deeply $chords, [ [qw/ C4 Ds4 Gs5 /], [qw/ F4 Gs4 Cs5 /] ], 'C# 4 midi imperfect inversion 1-1,2-1';

$chords = $mc->cadence(
    key       => 'C#',
    octave    => 4,
    type      => 'imperfect',
    inversion => { 1 => 1, 2 => 1 },
    picardy   => 1,
);
is_deeply $chords, [ [qw/ C4 Ds4 Gs5 /], [qw/ F4 A4 Cs5 /] ], 'C# 4 midi imperfect inversion 1-1,2-1 picardy';

$mc = Music::Cadence->new( format => 'midinum' );

$chords = $mc->cadence(
    key       => 'C',
    octave    => 3,
    type      => 'imperfect',
    inversion => { 1 => 1, 2 => 1 },
    picardy   => 1,
);
is_deeply $chords, [ [qw/ 59 50 115 /], [qw/ 52 56 108/] ], 'C# 3 midinum imperfect inversion 1-1,2-1 picardy';

my $got = $mc->remove_notes([1], [qw(Gs5 C5 Ds5)]);
is_deeply $got, ['Gs5','Ds5'], 'remove_notes';

$got = $mc->remove_notes([1,2], [qw(Gs5 C5 Ds5)]);
is_deeply $got, ['Gs5'], 'remove_notes';

$got = $mc->remove_notes([], [qw(Gs5 C5 Ds5)]);
is_deeply $got, [qw(Gs5 C5 Ds5)], 'remove_notes';

$got = $mc->remove_notes([9], [qw(Gs5 C5 Ds5)]);
is_deeply $got, [qw(Gs5 C5 Ds5)], 'remove_notes';

done_testing();
