#!/usr/bin/env perl
use strict;
use warnings;

use List::Util qw(zip);
use Music::Duration::Partition ();
use Music::Percussion::Tabla ();

my $bpm  = shift || 120;
my $bars = shift || 8;
my $size = shift || 4;

my $mdp = Music::Duration::Partition->new(
  size    => $size,
  pool    => [qw(qn den en dsn sn)],
  weights => [qw( 2   1  2   1  2)],
  groups  => [qw( 1   1  2   1  2)],
);

my $t = Music::Percussion::Tabla->new(
  file   => "$0.mid",
  bpm    => $bpm,
  bars   => $bars,
  reverb => 8,
);

my @motifs = $mdp->motifs(2);

my @bols = keys $t->patches->%*;

my @voices = map { $bols[ int rand @bols ] } $motifs[1]->@*;

for my $i (1 .. $t->bars) {
  if ($i % 2 == 0) {
    for my $dura ($motifs[0]->@*) {
      my $bol = $bols[ int rand @bols ];
      $t->strike($bol, $dura);
    }
  }
  else {
    for (zip \@voices, $motifs[1]) {
      my ($bol, $dura) = @$_;
      $t->strike($bol, $dura);
    }
  }
  $t->rest($t->quarter) unless $i == $t->bars;
}

$t->play_with_timidity;
# $t->write;
