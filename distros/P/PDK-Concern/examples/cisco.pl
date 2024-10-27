#!/usr/bin/env perl

use strict;
use warnings;
use v5.30;

use PDK::Device::Cisco;
use PDK::Concern::Netdisco::Cisco;
use Data::Dumper;
use Data::Printer;

my $ip = '192.168.10.101';
my $d  = PDK::Device::Cisco->new(host => $ip);
my $nd = PDK::Concern::Netdisco::Cisco->new(device => $d);
say Dumper $nd->explore_topology;
