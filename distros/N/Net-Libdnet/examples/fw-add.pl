#!/usr/bin/perl
use strict; use warnings;

my $rule = "@ARGV" || die("Pass rule");

use Net::Libdnet::Fw;

my $h = Net::Libdnet::Fw->new;
my $s = $h->add($rule);
print $s ? "Ok\n" : "Failed\n";
