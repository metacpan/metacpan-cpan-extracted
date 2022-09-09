#!/usr/bin/env perl

use 5.016;
use warnings;
use DDP;
use PDK::Device::Srx;

my $fw = PDK::Device::Srx->ssh(user => "root", password => "Cisc0123", host => '127.0.0.1');
