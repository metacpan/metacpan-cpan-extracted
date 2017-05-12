#!/usr/bin/perl
use strict; use warnings;

use Net::Libdnet::Eth;

my $h = Net::Libdnet::Eth->new(device => 'eth1');
print $h->get."\n";
$h->send('G'x60);
