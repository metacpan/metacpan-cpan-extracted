#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Net::IPv6Addr;
my $addr = "dead:beef:cafe:babe::f0ad";
Net::IPv6Addr::ipv6_parse($addr);
my $x = Net::IPv6Addr->new($addr);
print $x->to_string_preferred(), "\n";
