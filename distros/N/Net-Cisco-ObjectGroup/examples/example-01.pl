#!/usr/bin/perl

use strict;
use Net::Cisco::ObjectGroup;

my $og = Net::Cisco::ObjectGroup->new({
    type => 'network',
    name => 'test_group',
    description => 'THIS IS A TEST',
});

$og->push({net_addr => '123.123.123.123'});
$og->push({net_addr => '123.123.0.0', netmask => '255.255.0.0'});


my $og2 = Net::Cisco::ObjectGroup->new({
    type => 'network',
    name => 'referenced_group',
});

$og->push({group_object => $og2});

print $og->dump ."\n";

# object-group network test_group
#   description THIS IS A TEST
#   network-object host 123.123.123.123
#   network-object 123.123.0.0 255.255.0.0
#   group-object referenced_group

