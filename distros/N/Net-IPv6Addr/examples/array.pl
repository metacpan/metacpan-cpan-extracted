#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Net::IPv6Addr 'to_array';
my @int = to_array ('dead::beef');
my $ipobj = Net::IPv6Addr->new ('dead::beef');
my @int2 = $ipobj->to_array ();
print "@int\n@int2\n";
