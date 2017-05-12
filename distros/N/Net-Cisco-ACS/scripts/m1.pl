#!/usr/bin/perl

use lib qw(Net/Cisco/ACS/lib);
use Net::Cisco::ACS;
use Data::Dumper;

my $acs = Net::Cisco::ACS->new(hostname => '127.0.0.1:3000', ssl=>0, username => 'acsadmin', password => 'password');
print Dumper $acs->users;
