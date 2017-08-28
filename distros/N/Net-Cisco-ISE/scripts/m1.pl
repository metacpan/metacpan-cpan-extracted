#!/usr/bin/perl

use lib qw(../lib);
use Net::Cisco::ISE;
use Data::Dumper;

my $ise = Net::Cisco::ISE->new(hostname => 'localhost:3003', username => 'admin', password => 'Secret', ssl => 0);
print Dumper $ise->internalusers;
