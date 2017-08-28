#!/usr/bin/perl

use lib qw(../lib);
use Net::Cisco::ISE;
use Data::Dumper;


# users call only displayes a very limited set of information. Additional requests need to be made to retrieve explicit information
my $ise = Net::Cisco::ISE->new(hostname => '10.0.0.1', username => 'admin', password => 'Secret');
$ise->networkdevices;
