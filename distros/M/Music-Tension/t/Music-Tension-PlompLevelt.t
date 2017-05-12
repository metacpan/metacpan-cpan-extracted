#!perl

use strict;
use warnings;

use Test::Most;    # plan is down at bottom

use Music::Tension::PlompLevelt;
my $tension = Music::Tension::PlompLevelt->new;

isa_ok( $tension, 'Music::Tension::PlompLevelt' );

is( sprintf( "%.03f", $tension->frequencies( 440, 440 ) ),
  0.017, 'tension of frequency at unison' );
is( sprintf( "%.03f", $tension->frequencies( 440, 440 * 2 ) ),
  0.022, 'tension of frequency at octave' );
is( sprintf( "%.03f", $tension->frequencies( 440, 440 * 3 / 2 ) ),
  0.489, 'tension of frequency at perfect fifth' );
is( sprintf( "%.03f", $tension->frequencies( 440, 440 * 9 / 8 ) ),
  1.752, 'tension of frequency at greater tone (major 2nd)' );

# equal temperament has higher tension, excepting unison/octaves
is( sprintf( "%.03f", $tension->pitches( 69, 69 ) ),
  0.017, 'tension of pitches at unison' );

is( sprintf( "%.01f", scalar $tension->vertical( [qw/60 64 67/] ) ),
  3.6, 'tension of major triad (equal temperament)' );

if ( $ENV{AUTHOR_TEST_JMATES} ) {
  $tension = Music::Tension::PlompLevelt->new(normalize_amps => 1);

  # Just Intonation, Major (minor is 1 9/8 6/5 4/3 3/2 8/5 9/5), in
  # what should be least to most dissonant but the code is broken
  # right now so
  my @just_ratios = ( 1, 2, 3 / 2, 5 / 3, 4 / 3, 5 / 4, 15 / 8, 9 / 8 );

  diag "DBG some numbers to puzzle over";
  my $base_freq = 440;
  for my $r (@just_ratios) {
    diag sprintf "DBG freq %d:%d\t%.06f", $base_freq, $base_freq * $r,
      $tension->frequencies( $base_freq, $base_freq * $r );
  }
# $base_freq = 440;
# for my $f ($base_freq..$base_freq*3) {
#   diag sprintf "FOR_R freq %d %d %.06f", $base_freq, $f,
#     $tension->frequencies( $base_freq, $f );
# }

  undef $tension;
}

########################################################################
#
# new() params

my $mtc = Music::Tension::PlompLevelt->new(
  amplitudes          => { zeros => [qw/0 0 0/] },
  default_amp_profile => 'zeros',
  reference_frequency => 640,
);

is( $mtc->frequencies( 440, 495 ), 0, 'zero times anything is zero tension' );

# inherited from parent class
is( $mtc->pitch2freq(69), 640, 'pitch 69 to frequency, ref pitch 640' );

plan tests => 9;
