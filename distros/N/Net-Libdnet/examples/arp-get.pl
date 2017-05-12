#!/usr/bin/perl
use strict; use warnings;

my $ip = shift or die("Pass IP");

use Net::Libdnet::Arp;

my $h = Net::Libdnet::Arp->new;
my $mac = $h->get($ip);
$mac ? print "MAC: $mac\n" : print "Not in cache\n";
