#!perl

use strict;
use warnings;
use Test::Most tests => 61;
my $deeply = \&eq_or_diff;

use Music::Tension::Cope;
my $mt = Music::Tension::Cope->new;

# Worked out from p.233 [Cope 2005] example, XXX find his lookup tables
# in published code? If so, could have { metername => { beatnum => value, ...
# lookup hash included in this module.
is( $mt->metric( 1, 2 ), 0.05, 'metric 4/4 beat 1' );
is( $mt->metric( 2, 2 ), 0.1,  'metric 4/4 beat 2' );
is( $mt->metric( 3, 6 ), 0.05, 'metric 4/4 beat 2' );
is( $mt->metric( 4, 2 ), 0.2,  'metric 4/4 beat 2' );

dies_ok { $mt->metric } qr/positive numeric/;
dies_ok { $mt->metric(42) } qr/positive numeric/;
dies_ok { $mt->metric( 42,   "xa" ) } qr/positive numeric/;
dies_ok { $mt->metric( "xa", 42 ) } qr/positive numeric/;
dies_ok { $mt->metric( 42,   -1 ) } qr/positive numeric/;
dies_ok { $mt->metric( -1,   42 ) } qr/positive numeric/;

is( $mt->pitches( 0, 0 ),  0, 'unison tension' );
is( $mt->pitches( 0, 12 ), 0, 'octave tension' );

is( $mt->pitches( 0, 1 ),  1.0,  'minor 2nd tension' );
is( $mt->pitches( 0, 13 ), 0.98, 'minor 2nd +8va tension' );
# multiple octaves no more consonant
is( $mt->pitches( 0, 25 ), 0.98, 'minor 2nd +8va*2 tension' );

dies_ok { $mt->pitches } qr/required/;
dies_ok { $mt->pitches(42) } qr/required/;
dies_ok { $mt->pitches( undef, 42 ) } qr/required/;
dies_ok { $mt->pitches( "xa",  0 ) } qr/integer/;
dies_ok { $mt->pitches( 0,     "xa" ) } qr/integer/;

# approach mostly just calls ->pitches(0, x)
is( $mt->approach(0), 0,   'unison approach tension' );
is( $mt->approach(7), 0.1, 'fifth approach tension' );

dies_ok { $mt->approach } qr/required/;
dies_ok { $mt->approach("xa") } qr/integer/;

# frequencies just maps to equal temperament then calls pitches
is( $mt->frequencies( 261.6, 440 ), 0.25, 'major 6th via frequencies' );

dies_ok { $mt->frequencies } qr/two frequencies/;
dies_ok { $mt->frequencies(42) } qr/two frequencies/;
dies_ok { $mt->frequencies( 42,   "xa" ) } qr/positive number/;
dies_ok { $mt->frequencies( "xa", 42 ) } qr/positive number/;
dies_ok { $mt->frequencies( 42,   -1 ) } qr/positive number/;
dies_ok { $mt->frequencies( -1,   42 ) } qr/positive number/;

# vertical depends on ->pitches working
$deeply->(
    [ $mt->vertical( [qw/0 3 7/] ) ],
    [ 0.325, 0.1, 0.225, [ 0.225, 0.1 ] ],
    'vertical tension'
);
dies_ok { $mt->vertical } qr/array ref/;
dies_ok { $mt->vertical( {} ) } qr/array ref/;
dies_ok { $mt->vertical( [0] ) } qr/multiple elements/;

# repositioning edge cases
$deeply->(
    [ $mt->vertical( [qw/14 1 2 3 12 13/] ) ],
    [ 3.5, 0, 1, [ 0.9, 0, 1, 0.7, 0.9 ] ],
    'vertical reposition, single register'
);
$deeply->(
    [ $mt->vertical( [qw/60 11 12 13/] ) ],
    [ 1.9, 0, 1, [ 0.9, 0, 1 ] ],
    'vertical reposition, multiple registers'
);

is( $mt->duration( 0.3, 0.25 ),
    0.055, 'major triad qn duration given tension' );

# duration-supplied-pitch_set depends on ->vertical working
is( scalar $mt->duration( [qw/0 4 7/], 0.25 ),
    0.055, 'major triad qn duration lookup tension' );

dies_ok { $mt->duration( undef, 0.25 ) } qr/unknown pitch set/;

dies_ok { $mt->duration(0.3) } qr/positive value/;
dies_ok { $mt->duration( 0.3, "xa" ) } qr/positive value/;
dies_ok { $mt->duration( 0.3, -1 ) } qr/positive value/;

########################################################################
#
# new() params

my $mtc = Music::Tension::Cope->new(
    duration_weight     => 0.5,
    metric_weight       => 0.5,
    octave_adjust       => 0.2,
    reference_frequency => 640,
    tensions            => {
        0  => 0.33,
        1  => 0.5,
        2  => 0,
        3  => 0,
        4  => 0,
        5  => 0,
        6  => 0,
        7  => 0,
        8  => 0,
        9  => 0,
        10 => 0,
        11 => 0
    },
);
is( $mtc->pitches( 0, 0 ),  0.33, 'unison tension test (custom)' );
is( $mtc->pitches( 0, 13 ), 0.7,  'minor 2nd +8va tension test (custom)' );

is( $mtc->duration( 0.3, 0.25 ),
    0.275, 'major triad qn duration custom weight' );
is( $mtc->metric( 1, 2 ), 0.25, 'metric 4/4 beat 1 custom weight' );

# inherited from parent class
is( $mtc->pitch2freq(69), 640, 'pitch 69 to frequency, ref pitch 640' );

dies_ok { Music::Tension::Cope->new( duration_weight => "xa" ) };
dies_ok { Music::Tension::Cope->new( metric_weight   => "xa" ) };
dies_ok { Music::Tension::Cope->new( octave_adjust   => "xa" ) };

dies_ok { Music::Tension::Cope->new( tensions => undef ) };
dies_ok { Music::Tension::Cope->new( tensions => [] ) };
dies_ok {
    Music::Tension::Cope->new(
        tensions => {
            0  => 1,
            1  => 0,
            2  => 0,
            3  => 1,
            4  => 1,
            5  => 0,
            7  => 1,
            8  => 1,
            9  => 1,
            10 => 0,
            11 => 0,
        }
    )
};

# offset_tensions
my $vert = Music::Tension::Cope->new(
    octave_adjust => 0,
    tensions      => { map { +$_ => $_ } 0 .. 11 },
);
$deeply->(
    [ $vert->offset_tensions( [qw/62 65 64 62/], [qw/69 72 71 69/] ) ],
    [ [ 7, 7, 7, 7 ], [ 4, 8, 9 ], [ 5, 10 ], [7] ]
);

dies_ok { $vert->offset_tensions } qw/phrase1/;
dies_ok { $vert->offset_tensions( [] ) } qw/phrase1/;
dies_ok { $vert->offset_tensions( {} ) } qw/phrase1/;
dies_ok { $vert->offset_tensions( [qw/62 65 64 62/] ) } qw/phrase2/;
dies_ok { $vert->offset_tensions( [qw/62 65 64 62/], [] ) } qw/phrase2/;
dies_ok { $vert->offset_tensions( [qw/62 65 64 62/], {} ) } qw/phrase2/;
