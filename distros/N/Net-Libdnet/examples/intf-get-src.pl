#!/usr/bin/perl
use strict; use warnings;

my $src = shift || die("Pass source IP");

use Net::Libdnet::Intf;

my $h = Net::Libdnet::Intf->new;
my $info = $h->getSrc($src) or die("FATAL: getSrc");
print $info->print."\n";
