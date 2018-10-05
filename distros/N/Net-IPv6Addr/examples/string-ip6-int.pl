#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Net::IPv6Addr 'to_string_ip6_int';
my $s = to_string_ip6_int ('dead::beef');
my $ipobj = Net::IPv6Addr->new ('dead::beef');
my $s2 = $ipobj->to_string_ip6_int ();
print "$s\n$s2\n";
