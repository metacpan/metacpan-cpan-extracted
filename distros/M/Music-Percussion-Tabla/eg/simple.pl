#!/usr/bin/env perl
use strict;
use warnings;

use Music::Percussion::Tabla ();

my $t = Music::Percussion::Tabla->new(
  signature => '3/4',
  bars      => 64,
  bpm       => 320,
);

for (1 .. $t->bars) {
  $t->strike(['ta', 'ke']);
  $t->strike('ge');
  $t->strike('ke');
  $t->strike('ta');
  $t->strike(['ge', 'ke']);
  $t->strike('dha');
}

# $t->play_with_timidity;
$t->write;
# $t->timidity_cfg('/Users/you/timidity.cfg');
