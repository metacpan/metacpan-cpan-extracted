#!/usr/local/bin/perl -w

use strict;

use Getopt::Std;
use Time::Local;

my %opts;
getopts('d?', \%opts);

use NBU;
NBU->debug($opts{'d'});

NBU::Image->populate;

my @l = NBU::Image->list;
print "There are $#l images\n";

my %retentionTotal;
my %retentionVolumes;
my %inUse;
my $total = 0;
for my $image (@l) {
  next if (!defined($image->size));

  my $size = $image->size / 1024;

  my $rlc = $image->density.":".$image->retention->level;
  $retentionTotal{$rlc} += $size;

  #
  # To ensure we only count each volume once (it may contain many
  # images) we tag each one.  The tag is further qualified with the
  # volume's retention level and density since occasionally things
  # change over time and a single volume gets re-used across different
  # retention levels and/or densities...
  if (!exists($inUse{$rlc.$image->volume->id})) {
    if (!exists($retentionVolumes{$rlc})) {
      $retentionVolumes{$rlc} = 1;
    }
    else {
      $retentionVolumes{$rlc} += 1;
    }
    $inUse{$rlc.$image->volume->id} = +1;
  }
  $total += $size;
}

for my $l (sort (keys %retentionTotal)) {
  my $rlt = sprintf("%10.2f", $retentionTotal{$l}/1024);
  my $rlc = $retentionVolumes{$l};
  my ($density, $rl) = split(':', $l);
  my $r = NBU::Retention->byLevel($rl);
  print $rlt."Gb at ".$r->description." on $rlc ".$density." volumes\n";
}

$total = sprintf("%.2f", $total/1024);
print "Total size is ${total}Gb\n";
