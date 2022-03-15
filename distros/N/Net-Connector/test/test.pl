#!/usr/bin/perl
use 5.016;
use warnings FATAL => 'all';

use Net::Connector::Cisco::Ios;
use Data::Printer;
use Data::Dumper;

my $device = Net::Connector::Cisco::Ios->new(
  host     => '192.168.8.80',
  username => "cisco",
  password => "cisco"
);
say Dumper $device->healthCheckConfig;
