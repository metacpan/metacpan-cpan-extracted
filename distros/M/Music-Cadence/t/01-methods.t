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

throws_ok { $mc->cadence( key => 'X' ) }
    qr/unknown chord/, 'unknown key';

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
is_deeply $chords, [ [qw/ G B D /], [qw/ C E G /] ], 'C 0 perfect';

$chords = $mc->cadence(
    key    => 'C#',
    octave => 4,
);
is_deeply $chords, [ [qw/ G#4 C4 D#4 /], [qw/ C#4 F4 G#4 /] ], 'C# 4 perfect';

$chords = $mc->cadence( type => 'plagal' );
is_deeply $chords, [ [qw/ F A C /], [qw/ C E G /] ], 'C 4 plagal';

$chords = $mc->cadence(
    key  => 'C#',
    type => 'plagal',
);
is_deeply $chords, [ [qw/ F# A# C# /], [qw/ C# F G# /] ], 'C# 0 plagal';

$chords = $mc->cadence(
    type    => 'half',
    leading => 2,
);
is_deeply $chords, [ [qw/ D F A /], [qw/ G B D /] ], 'C 0 half';

$chords = $mc->cadence(
    key     => 'C#',
    type    => 'half',
    leading => 2,
);
is_deeply $chords, [ [qw/ D# F# A# /], [qw/ G# C D# /] ], 'C# 0 half';

$chords = $mc->cadence(
    type    => 'half',
    leading => 7,
);
is_deeply $chords, [ [qw/ B D F /], [qw/ G B D /] ], 'C 0 half';

$chords = $mc->cadence(
    key     => 'D',
    scale   => 'dorian',
    type    => 'half',
    leading => 6,
);
is_deeply $chords, [ [qw/ B D F /], [qw/ A C E /] ], 'D 0 dorian half';

$chords = $mc->cadence(
    key     => 'E',
    scale   => 'phrygian',
    type    => 'half',
    leading => 5,
);
is_deeply $chords, [ [qw/ B D F /], [qw/ B D F /] ], 'E 0 phrygian half';

$chords = $mc->cadence( type => 'deceptive' );
is_deeply $chords, [ [qw/ G B D /], [qw/ A C E /] ], 'C 0 deceptive';

$chords = $mc->cadence(
    key       => 'C#',
    type      => 'deceptive',
    variation => 2,
);
is_deeply $chords, [ [qw/ G# C D# /], [qw/ F# A# C# /] ], 'C# 0 deceptive';

$mc = Music::Cadence->new(
    key    => 'C#',
    octave => 5,
    format => 'midi',
);

$chords = $mc->cadence( type => 'perfect' );
is_deeply $chords, [ [qw/ Gs5 C5 Ds5 /], [qw/ Cs5 F5 Gs5 /] ], 'C# 5 perfect midi';

$mc = Music::Cadence->new(
    key    => 'C',
    octave => 4,
    format => 'midinum',
);

$chords = $mc->cadence( type => 'perfect' );
is_deeply $chords, [ [ 67, 71, 62 ], [ 60, 64, 67 ] ], 'C 4 perfect midinum';

$mc = Music::Cadence->new(
    key    => 'C',
    octave => -1,
    format => 'midinum',
);

$chords = $mc->cadence( type => 'perfect' );
is_deeply $chords, [ [ 7, 11, 2 ], [ 0, 4, 7 ] ], 'C -1 perfect midinum';

done_testing();
