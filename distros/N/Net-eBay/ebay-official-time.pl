#!/usr/bin/perl

use strict;
use warnings;
  
use Net::eBay;
my $eBay = new Net::eBay;
$eBay->setDefaults( { API => 2 } );

my $t = $eBay->officialTime;

$t =~ s/T/ /g;
$t =~ s/Z/ GMT/;

print "eBay Official time = $t\n";
