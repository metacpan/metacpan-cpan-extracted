#!/usr/bin/perl

use lib qw(../lib);
use Net::Cisco::ISE;
use Net::Cisco::ISE::IdentityGroup;
use Data::Dumper;

my $ise = Net::Cisco::ISE->new(hostname => '10.0.0.1', username => 'admin', password => 'Secret');
my $identitygroup = Net::Cisco::ISE::IdentityGroup->new(
"name"=>"foobar", 
"description" => "Generic Group",
);

# This won't work!!
#$ise->create($identitygroup);
print $Net::Cisco::ISE::ERROR;
