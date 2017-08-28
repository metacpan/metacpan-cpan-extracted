#!/usr/bin/perl

use lib qw(../lib);
use Net::Cisco::ISE;
use Data::Dumper;


# users call only displayes a very limited set of information. Additional requests need to be made to retrieve explicit information
my $ise = Net::Cisco::ISE->new(hostname => '10.0.0.1', username => 'admin', password => 'Secret');
my @devices = $ise->networkdevices(id=>"2509fa00-034f-11e7-a0a4-005056ad14a4");
for my $device (@devices)
{ my $data = $device->toXML; print $device->header($data, $device); }
