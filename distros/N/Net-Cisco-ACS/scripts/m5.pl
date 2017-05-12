#!/usr/bin/perl

use lib qw(Net/Cisco/ACS/lib);
use Net::Cisco::ACS::Device;
use Data::Dumper;

my $device = Net::Cisco::ACS::Device->new();
$device->ips([{netmask => "32", ipAddress=>"10.0.0.1"}]); 
print Dumper $device;
