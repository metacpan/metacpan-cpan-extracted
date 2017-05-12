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
my $device = Net::Intermapper::Device->new(Name=>"testDevice", MapName=>"TestMap", MapPath=>"/TestMap", Address=>"10.0.0.1");
$intermapper->create($device);
$device = $intermapper->devices->{'10.0.0.1'}; # No DNS!?!
print "OK\n" if $device->Address eq "10.0.0.1";

print Dumper $intermapper->delete($device);
$device = $intermapper->devices->{"10.0.0.1"};
print Dumper $device;
