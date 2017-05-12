#!/usr/bin/perl

use strict;
use warnings;
  
use Net::eBay;
use Data::Dumper;

my $eBay = new Net::eBay;

my $result = $eBay->submitRequest( "GetApiAccessRules", {} );

print Dumper( $result );

my $limits = $result->{ApiAccessRule};

foreach my $limit (@$limits) {
  next unless $limit->{CallName} eq 'ApplicationAggregate';
  
  print "$limit->{CallName}: $limit->{PeriodicUsage} out of $limit->{PeriodicHardLimit} \n";
}
