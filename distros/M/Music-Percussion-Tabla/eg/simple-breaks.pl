#!/usr/bin/env perl
use strict;
use warnings;

# use MIDI::Util qw(dura_size ticks);
use Music::Percussion::Tabla ();

my $t = Music::Percussion::Tabla->new(
  bpm => 120,
);

# my $ticks = ticks($t->score);

for (1 .. $t->bars) {
  $t->strike('ke', $t->sixteenth) for 1 .. 4;
  # my $size = dura_size($t->quarter);
  # my $dura = 'd' . $ticks * ($size - $t->counter);
  $t->strike('ge', $t->dotted_half);
  # print $t->counter, "\n";
  # $t->counter(0);
}

$t->play_with_timidity;
$t->write;
# $t->timidity_cfg('/Users/you/timidity.cfg');
