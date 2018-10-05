#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Net::IPv6Addr 'to_bigint';
my $int = to_bigint ('dead::beef');
my $ipobj = Net::IPv6Addr->new ('dead::beef');
my $int2 = $ipobj->to_bigint ();
print "$int\n$int2\n";
