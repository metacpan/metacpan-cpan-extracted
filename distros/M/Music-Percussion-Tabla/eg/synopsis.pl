#!/usr/bin/env perl
use strict;
use warnings;

use Music::Percussion::Tabla ();

my $t = Music::Percussion::Tabla->new;

for (1 .. $t->bars) {
  $t->strike('ta', $t->eighth);
  $t->strike('ta', $t->eighth);
  $t->strike('dha');
  $t->strike('ge');
  $t->rest($t->quarter);
}

$t->teentaal($t->eighth)  for 1 .. $t->bars;
$t->keherawa($t->eighth)  for 1 .. $t->bars;
$t->jhaptaal($t->eighth)  for 1 .. $t->bars;
$t->dadra($t->eighth)     for 1 .. $t->bars;
$t->rupaktaal($t->eighth) for 1 .. $t->bars;

$t->play_with_timidity;
# $t->write;
# $t->timidity_cfg('/Users/you/timidity.cfg');
