#!perl

use strict;
use warnings;

use Test::Most;    # plan is down at bottom

use Music::Tension::Cope;
my $mt = Music::Tension::Cope->new;

isa_ok( $mt, 'Music::Tension::Cope' );

# Worked out from p.233 [Cope 2005] example, XXX find his lookup tables
# in published code? If so, could have { metername => { beatnum => value, ...
# lookup hash included in this module.
is( $mt->metric( 1, 2 ), 0.05, 'metric 4/4 beat 1' );
is( $mt->metric( 2, 2 ), 0.1,  'metric 4/4 beat 2' );
is( $mt->metric( 3, 6 ), 0.05, 'metric 4/4 beat 2' );
is( $mt->metric( 4, 2 ), 0.2,  'metric 4/4 beat 2' );

is( $mt->pitches( 0, 0 ),  0, 'unison tension' );
is( $mt->pitches( 0, 12 ), 0, 'octave tension' );

is( $mt->pitches( 0, 1 ),  1.0,  'minor 2nd tension' );
is( $mt->pitches( 0, 13 ), 0.98, 'minor 2nd +8va tension' );
# multiple octaves no more consonant
is( $mt->pitches( 0, 25 ), 0.98, 'minor 2nd +8va*2 tension' );

# approach mostly just calls ->pitches(0, x)
is( $mt->approach(0), 0,   'unison approach tension' );
is( $mt->approach(7), 0.1, 'fifth approach tension' );

# frequencies just maps to equal temperament then calls pitches
is( $mt->frequencies( 261.6, 440 ), 0.25, 'major 6th via frequencies' );

# vertical depends on ->pitches working
is_deeply(
  [ $mt->vertical( [qw/0 3 7/] ) ],
  [ 0.325, 0.1, 0.225, [ 0.225, 0.1 ] ],
  'vertical tension'
);

# repositioning edge cases
is_deeply(
  [ $mt->vertical( [qw/14 1 2 3 12 13/] ) ],
  [ 3.5, 0, 1, [ 0.9, 0, 1, 0.7, 0.9 ] ],
  'vertical reposition, single register'
);
is_deeply(
  [ $mt->vertical( [qw/60 11 12 13/] ) ],
  [ 1.9, 0, 1, [ 0.9, 0, 1 ] ],
  'vertical reposition, multiple registers'
);

is( $mt->duration( 0.3, 0.25 ),
  0.055, 'major triad qn duration given tension' );

# duration-supplied-pitch_set depends on ->vertical working
is( scalar $mt->duration( [qw/0 4 7/], 0.25 ),
  0.055, 'major triad qn duration lookup tension' );

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

plan tests => 23;
