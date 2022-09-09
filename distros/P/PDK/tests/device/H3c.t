#!/usr/bin/env perl

use 5.016;
use warnings;
use DDP;
use PDK::Device::H3c;

my $fw = PDK::Device::H3c->ssh(user => "root", password => "Cisc0123", host => '127.0.0.1');
