#!/usr/bin/perl

use lib::Net::Generatus;
use Data::Dumper;
my $status = Net::Generatus->Status();
print "$status\n";

my $status = Net::Generatus->Status({tag => 'insults'});
print "$status\n";
 
