#!perl
#
# modal_map proved tricky enough to need a bad sequel (or was never really
# fully thought through wrt transpose).

use Test::Most;    # plan is down at bottom

my $deeply = \&eq_or_diff;

use Music::Canon;
my $mc = Music::Canon->new;

# some more scale tests + transpose
$mc = Music::Canon->new( contrary => 0, retrograde => 0 );
$mc->set_transpose(4);
$deeply->(
  [ $mc->modal_map( 60, 59, 57, 55, 53, 52, 50, 48 ) ],
  [ 64, 62, 60, 59, 57, 55, 53, 52 ],
  'Major I->iii'
);

$mc = Music::Canon->new( contrary => 0, retrograde => 0 );
# Middle c (60) -> g (55) in g-minor, transpose from scale degree 1 (g)
# to 3 (bes)
# $mc->set_modal_pitches( 55, 58 );
$mc->set_modal_scale_in('aeolian');
$mc->set_modal_scale_out('aeolian');
$mc->set_transpose('bes');
# 'got' pattern not possible using scale intervals? something cut?
$deeply->(
  [ $mc->modal_map( 55, 53, 51, 50, 48, 46, 45, 43 ) ],
  [ 58, 57, 55, 53, 51, 50, 48, 46 ],
  'minor i->III'
);

# Bug in v1.00 revealed by trying to do things in Bflat Major... or really how
# transpose should be defined when the tonic is a non-(n%12==0) pitch.
$mc = Music::Canon->new( contrary => 0, retrograde => 0 );
$mc->set_modal_pitches( 70, 70 );
$mc->set_transpose(2); # Bes to C
$deeply->(
  [ $mc->modal_map( qw/74 70 69 70 74 75 72 71 72 76 77/ ) ],
  [                 qw/75 72 70 72 75 77 74 73 74 78 79/ ],
  'bit of a subject'
);

$mc = Music::Canon->new;
$mc->modal_hook( sub { "testy" } );
$deeply->(
  [ $mc->modal_map( 0, 1 ) ],
  [ 'testy', 0 ],
  "major chromatic conversion 0 to 1 with hook"
);

# TODO need to work out handling of transpose to chromatic or unpossible scale
# degrees.

plan tests => 4;
