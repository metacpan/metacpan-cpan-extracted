#!/usr/local/bin/perl

use strict;
use Getopt::Std;

use NBU;

my %opts;
getopts('ed', \%opts);

NBU::->debug($opts{'d'});

NBU::License->populate;

my @ll = NBU::License->list();

foreach my $l (@ll) {
  print "License key ".$l->key."\n";
    print "  Installed on:\n   ";
    foreach my $hn ($l->hosts) {
      print " $hn";
    }
    print "\n";
    print "  Product ".$l->productDescription($l->product)."\n";
    print "  Server Tier ".$l->serverTier."\n";
    if (defined($l->expiration) && ($l->expiration < localtime())) {
      print "  ** EXPIRED: ".localtime($l->expiration)."\n";
    }
    else {
      print "  Expires: ".(defined($l->expiration) ? localtime($l->expiration) : "Never")."\n";
    }
    my @fcl = $l->features;
    foreach my $fc (@fcl) {
      print "    Feature ".$l->featureDescription($fc)."\n";
    }
}
