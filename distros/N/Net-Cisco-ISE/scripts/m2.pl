#!/usr/bin/perl

use lib qw(../lib);
use Net::Cisco::ISE;
use Data::Dumper;

my $ise = Net::Cisco::ISE->new(hostname => '10.0.0.1', username => 'admin', password => 'Secret');
print Dumper $ise->internalusers(id=>"b74a0ef2-b29c-40e3-a0d1-4c0dfb51ace9");
