#!/usr/bin/perl
use strict; use warnings;

my $dst = shift || die("Pass dst");

use Net::Libdnet::Route;

my $h = Net::Libdnet::Route->new;
my $ret = $h->get($dst);
$ret ? print "GW: $ret\n" : print "Same subnet\n";
