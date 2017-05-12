#!/usr/bin/perl

use Net::Appliance::Phrasebook;
 
my $pb = Net::Appliance::Phrasebook->new(
    platform => 'IOS',
    source   => '/a/file/somewhere.yml', # optional
);
 
print $pb->fetch('prompt'), "\n";
print $pb->fetch('a_command_alias'), "\n";

