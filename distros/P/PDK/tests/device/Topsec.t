#!/usr/bin/env perl

use 5.016;
use warnings;
use DDP;
use PDK::Device::Topsec;

my $fw = PDK::Device::Topsec->ssh(user => "root", password => "Cisc0123", host => '127.0.0.1');
