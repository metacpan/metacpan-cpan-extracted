use strict;
use warnings;
use Test2::V0;

use Music::Harmonica::TabsCreator 'tune_to_tab';

is({ tune_to_tab('CDEFGAB') }->{richter}, { C => [[4, -4, 5, -5, 6, -6, -7]] });
is({ tune_to_tab('B>DbEbEGbAbBb') }->{richter}, { B => [[4, -4, 5, -5, 6, -6, -7]] });

is({ tune_to_tab('C D Db E Gb F G B Bb A Ab', max_bends => 3) }->{richter},
   { C => [[qw(1 -1 -1' 2 -2' -2" 3 -3 -3' -3" -3"')]] });

is({ tune_to_tab('C D Db E Gb F G B Bb A Ab', max_bends => 2) }->{richter}, U());
is({ tune_to_tab('C D Db E Gb F G B Bb A', max_bends => 2) }->{richter},
   { C => [[qw(1 -1 -1' 2 -2' -2" 3 -3 -3' -3")]] });

# We test that we’re using 3 in the output and not -2.
is({ tune_to_tab("CEGC'''") }->{richter}, { C => [[1, 2, 3, 10]] });

is({ tune_to_tab('CDEGA>F#>>C') }->{melody_maker}, { G => [[1, -1, 2, -2, 3, -5, 10]] });

{
  my %t = tune_to_tab('C');
  ok(exists $t{richter});
  ok(exists $t{harmonic_minor});
}

{
  my %t = tune_to_tab('C', tunings => ['foo']);
  ok(!exists $t{richter});
  ok(!exists $t{harmonic_minor});
}

{
  my %t = tune_to_tab('C', tunings => ['richter']);
  ok(exists $t{richter});
  ok(!exists $t{harmonic_minor});
}

{
  my %t = tune_to_tab('C', tunings => ['richter', 'harmonic_minor']);
  ok(exists $t{richter});
  ok(exists $t{harmonic_minor});
}

done_testing;
