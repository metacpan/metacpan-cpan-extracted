#!/usr/local/bin/perl

use strict;

use Getopt::Std;
use Time::Local;

my %opts;
getopts('d', \%opts);


use NBU;
NBU->debug($opts{'d'});

NBU::StorageUnit->populate;

foreach my $stu (NBU::StorageUnit->list) {
  if (defined($stu->host)) {
    print $stu->host->name.": ";
  }
  else {
    print "<none>: ";
  }
  print $stu->label." is of type ".$stu->type."\n";
  if ($stu->robot && (($stu->type == 2) || ($stu->type == 3))) {
    print " ".$stu->driveCount." ".$stu->density." drives are controlled through ".$stu->robot->type." robot ".$stu->robot->id."\n";
  }
  else {
#    print " ".$stu->driveCount." ".$stu->density."\n";
  }
  print " Up to ".$stu->mpx." streams can be multiplexed to each drive\n";
}
