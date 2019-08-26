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
is $mc->format, '', 'default format';

throws_ok { $mc->cadence( key => 'X' ) }
    qr/unknown chord/, 'unknown key';

throws_ok { $mc->cadence( type => 'foo' ) }
    qr/unknown cadence/, 'unknown cadence';

throws_ok { $mc->cadence( scale => 'foo' ) }
    qr/unknown scale/, 'unknown scale';

throws_ok { $mc->cadence( leading => 666 ) }
    qr/unknown leader/, 'unknown leader';

my $chords = $mc->cadence;
is_deeply $chords, [ [qw/ G B D /], [qw/ C E G /] ], 'C perfect';

$chords = $mc->cadence(
    key    => 'C#',
    octave => 4,
);
is_deeply $chords, [ [qw/ G#4 C4 D#4 /], [qw/ C#4 F4 G#4 /] ], 'C# perfect';

$chords = $mc->cadence( type => 'plagal' );
is_deeply $chords, [ [qw/ F A C /], [qw/ C E G /] ], 'C plagal';

$chords = $mc->cadence(
    key  => 'C#',
    type => 'plagal',
);
is_deeply $chords, [ [qw/ F# A# C# /], [qw/ C# F G# /] ], 'C# plagal';

$chords = $mc->cadence(
    type    => 'half',
    leading => 2,
);
is_deeply $chords, [ [qw/ D F A /], [qw/ G B D /] ], 'C half';

$chords = $mc->cadence(
    key     => 'C#',
    type    => 'half',
    leading => 2,
);
is_deeply $chords, [ [qw/ D# F# A# /], [qw/ G# C D# /] ], 'C# half';

$chords = $mc->cadence(
    type    => 'half',
    leading => 7,
);
is_deeply $chords, [ [qw/ B D F /], [qw/ G B D /] ], 'C half';

$chords = $mc->cadence(
    key     => 'D',
    scale   => 'dorian',
    type    => 'half',
    leading => 6,
);
is_deeply $chords, [ [qw/ B D F /], [qw/ A C E /] ], 'D dorian half';

$chords = $mc->cadence(
    key     => 'E',
    scale   => 'phrygian',
    type    => 'half',
    leading => 5,
);
is_deeply $chords, [ [qw/ B D F /], [qw/ B D F /] ], 'E phrygian half';

$chords = $mc->cadence( type => 'deceptive' );
is_deeply $chords, [ [qw/ G B D /], [qw/ A C E /] ], 'C deceptive';

$chords = $mc->cadence(
    key       => 'C#',
    type      => 'deceptive',
    variation => 2,
);
is_deeply $chords, [ [qw/ G# C D# /], [qw/ F# A# C# /] ], 'C# deceptive';

$mc = Music::Cadence->new(
    key    => 'C#',
    octave => 5,
    format => 'midi',
);

$chords = $mc->cadence( type => 'perfect' );
is_deeply $chords, [ [qw/ Gs5 C5 Ds5 /], [qw/ Cs5 F5 Gs5 /] ], 'C# perfect midi';

done_testing();
