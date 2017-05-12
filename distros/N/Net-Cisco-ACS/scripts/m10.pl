#!/usr/bin/perl

use lib qw(Net/Cisco/ACS/lib);
use Net::Cisco::ACS;
use Data::Dumper;

my $acs = Net::Cisco::ACS->new(hostname => '10.0.0.0', username => 'acsadmin', password => 'password');
my $device = $acs->devices("name","Main_Router");
$device->id("0");
$device->name("FOOBAR");
$device->ips([{netMask => "32", ipAddress=>"10.0.0.1"}]); 
$device->description("Test Device");
my $id = $acs->create($device);
print "Record ID is $id" if $id;
print $Net::Cisco::ACS::ERROR unless $id;
