#!/usr/local/bin/perl

use strict;

use Getopt::Std;
use Time::Local;

my %opts;
getopts('dtscvM:', \%opts);

if ($opts{'v'}) {
  $opts{'c'} = $opts{'t'} = $opts{'s'} = 1;
}


use NBU;
NBU->debug($opts{'d'});

my $master;
if ($opts{'M'}) {
  $master = NBU::Host->new($opts{'M'});
}
else {
  my @masters = NBU->masters;  $master = $masters[0];
}

foreach my $stu (NBU::StorageUnit->list($master)) {
  NBU::Drive->populate($stu->host)
    unless (!defined($stu->host));
}

for my $robot (NBU::Robot->farm) {
  next unless (defined($robot));
  print "Robot ".$robot->id;
  print " controlled from ".$robot->host->name if (defined($robot->host));
  print "\n";
  for my $drive (sort {$a->robotDriveIndex <=> $b->robotDriveIndex} $robot->drives) {
    print "  ".($drive->down ? "v" : "^");
    printf(" %2u", $drive->robotDriveIndex);
    printf(" %-8s", $drive->name);
    printf(" (%2u)", $drive->id) if ($opts{'v'});
    if ($opts{'t'}) {
      if ($drive->busy) {
	print " (".$drive->mount->volume->id.")";
      }
      else {
	print " (      )";
      }
    }
    print " SN:".$drive->serialNumber if ($opts{'s'});
    print " Cleaned: ".substr(localtime($drive->lastCleaned), 4) if ($opts{'c'});
    print ": ".$drive->comment if ($opts{'v'});

    print "\n";
  }
}
