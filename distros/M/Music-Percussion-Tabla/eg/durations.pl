#!/usr/bin/env perl
use strict;
use warnings;

use Music::Duration::Partition ();
use Music::Percussion::Tabla ();

my $mdp = Music::Duration::Partition->new(
  size   => 5,
  pool   => [qw(qn den en dsn sn)],
  groups => [qw( 1   1  2   1  2)],
);

my $motif = $mdp->motif;

my $t = Music::Percussion::Tabla->new;

my @bols = keys $t->patches->%*;

for my $i (1 .. $t->bars) {
  for my $dura (@$motif) {
    my $bol = $bols[ int rand @bols ];
    $t->strike($bol, $dura);
  }
}

$t->play_with_timidity;
# $t->write;
# $t->timidity_cfg('/Users/you/timidity.cfg');
