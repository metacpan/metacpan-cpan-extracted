#!/usr/bin/env perl
use strict;
use warnings;
no warnings 'qw';

use Test::More;

use_ok 'Music::Cadence';

my $mc = Music::Cadence->new;
isa_ok $mc, 'Music::Cadence';

my $chords = $mc->cadence( type => 'unknown' );
is_deeply $chords, [], 'unknown cadence';

$chords = $mc->cadence;
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
    leading => 6,
);
is_deeply $chords, [ [qw/ A# C# F /], [qw/ G# C D# /] ], 'C# half';

$chords = $mc->cadence( type => 'deceptive' );
is_deeply $chords, [ [qw/ G B D /], [qw/ A C E /] ], 'C deceptive';

$chords = $mc->cadence(
    key       => 'C#',
    type      => 'deceptive',
    variation => 2,
);
is_deeply $chords, [ [qw/ G# C D# /], [qw/ F# A# C# /] ], 'C# deceptive';

done_testing();
