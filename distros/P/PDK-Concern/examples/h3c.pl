#!/usr/bin/env perl

use strict;
use warnings;
use v5.30;

use PDK::Device::H3c;
use PDK::Concern::H3c::Netdisco;
use Data::Dumper;
use Data::Printer;

my $ip = '192.168.10.101';
my $d = PDK::Device::H3c->new(host => $ip);

my $nd = PDK::Concern::H3c::Netdisco->new(device => $d);
say Dumper $nd->explore_topology;