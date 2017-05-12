#!/usr/bin/perl

use lib qw(Net/Intermapper/lib);
use Net::Intermapper;
use Net::Intermapper::Device;

use Data::Dumper;
use warnings;
use strict;

# Adding and updating requires a different username and password
# Use the user you configured for the web-based configuration
my $intermapper = Net::Intermapper->new(hostname=>"10.0.0.1", username=>"admin", password=>"nmsadmin", format=>"tab");
for my $i (1..10)
{ my $device = Net::Intermapper::Device->new(Name=>"testDevice$i", MapName=>"TestMap", MapPath=>"/TestMap", Address=>"10.0.0.$i");
  $intermapper->create($device);
}

for my $i (1..10) # This part is not working yet!
{ my $device = $intermapper->devices->{"10.0.0.$i"};
  print "OK\n" if $device->Name eq "testDevice$i";
}
