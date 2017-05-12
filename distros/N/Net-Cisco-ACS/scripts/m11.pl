#!/usr/bin/perl

use lib qw(Net/Cisco/ACS/lib);
use Net::Cisco::ACS;
use Data::Dumper;

my $acs = Net::Cisco::ACS->new(hostname => '10.0.0.0', username => 'acsadmin', password => 'password');

my $user = $acs->users("name","Main_Router");
$user->id("0");
$user->name("foobar");
$user->description("Test User");
$user->password("qwerASDF123"); #Random, I swear
$user->enablePassword("qwerASDF123");
my $id = $acs->create($user);
print "Record ID is $id" if $id;
print $Net::Cisco::ACS::ERROR unless $id;

# --

my $user = $acs->users("name","foobar");
$user->description("Test User #2");
my $id = $acs->update($user);
print "Record ID is $id" if $id;
print $Net::Cisco::ACS::ERROR unless $id;
