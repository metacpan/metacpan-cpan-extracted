#!/usr/bin/perl

use lib qw(Net/Cisco/ACS/lib);
use Net::Cisco::ACS;
use Data::Dumper;

my $acs = Net::Cisco::ACS->new(hostname => '10.0.0.0', username => 'acsadmin', password => 'password');
my $user = $acs->users("name","acsadmin");
print $user->toXML;
print "-"x100,"\n";
$user->id("0");
$user->name("foobar");
$user->description("Test User");
print $user->toXML;