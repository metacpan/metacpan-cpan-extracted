#!/usr/bin/perl
use strict; use warnings;

my $ip = shift or die("Pass IP");

use Net::Libdnet::Arp;

my $h = Net::Libdnet::Arp->new;
my $success = $h->delete($ip);
$success ? print "Ok\n" : print "Failed\n";
