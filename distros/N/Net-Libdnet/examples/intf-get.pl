#!/usr/bin/perl
use strict; use warnings;

use Net::Libdnet::Intf;

my $intf = shift || die("Pass interface");

my $h = Net::Libdnet::Intf->new;
my $info = $h->get($intf) or die("FATAL: get");
print $info->print."\n";
