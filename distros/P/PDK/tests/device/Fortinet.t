#!/usr/bin/env perl

use 5.016;
use warnings;
use DDP;
use PDK::Device::Fortinet;

print p my $fw = PDK::Device::Fortinet->ssh(user => "root", password => "Cisc0123", host => '127.0.0.1');
