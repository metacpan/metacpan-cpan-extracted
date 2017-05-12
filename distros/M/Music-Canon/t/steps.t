#!perl

use Test::Most;    # plan is down at bottom

my $deeply = \&eq_or_diff;

use Music::Canon;
my $mc = Music::Canon->new;

$deeply->(
  [ $mc->steps( 60, 62, ($mc->get_modal_scale_in)[0] ) ],
  # one interval, no chrome, last interval was major second
  [ 1, 0, 0, 2 ],
  'C-Major One Step Up'
);

$deeply->(
  [ $mc->steps( 60, 66, ($mc->get_modal_scale_in)[0] ) ],
  # Four intervals (as counter walked past F# to G), one semitone chromatic,
  # last interval was major second (F->G). (Subsequent uses may need to adjust
  # the steps, depending on how intervals are counted.)
  [ 4, 1, 0, 2 ],
  'C-Major Tritone Up'
);

plan tests => 2;
