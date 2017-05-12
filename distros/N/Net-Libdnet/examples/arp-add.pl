#!/usr/bin/perl
use strict; use warnings;

my $ip  = shift or die("Pass IP");
my $mac = shift or die("Pass MAC");

use Net::Libdnet::Arp;

my $h = Net::Libdnet::Arp->new;
my $success = $h->add($ip, $mac);
$success ? print "Ok\n", : print "Failed\n";
