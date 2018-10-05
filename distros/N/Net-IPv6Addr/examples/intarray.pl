#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Net::IPv6Addr 'to_intarray';
my @int = to_intarray ('dead::beef');
my $ipobj = Net::IPv6Addr->new ('dead::beef');
my @int2 = $ipobj->to_intarray ();
print "@int\n@int2\n";
