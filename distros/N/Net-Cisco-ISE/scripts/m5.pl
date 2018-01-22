#!/usr/bin/perl

use lib qw(../lib);
use Net::Cisco::ISE;
use Data::Dumper;

my $ise = Net::Cisco::ISE->new(hostname => '10.0.0.1', username => 'admin', password => 'Secret');
my $networkdevices = $ise->networkdevices;
for my $name (keys %{$networkdevices})
{  print Dumper $ise->networkdevices("id" => $networkdevices->{$name}->id);
}
