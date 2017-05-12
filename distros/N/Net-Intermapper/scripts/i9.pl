#!/usr/bin/perl

use lib qw(Net/Intermapper/lib);
use Net::Intermapper;
use Data::Dumper;
use warnings;
use strict;

my $intermapper = Net::Intermapper->new(hostname=>"10.0.0.1", username=>"admin", password=>"nmsadmin");
my %maps = % { $intermapper->maps };
my @mapnames = keys %maps;
my $header = 0;
for my $map (@mapnames)
{ print $maps{$map}->header unless $header;
  print $maps{$map}->toCSV;
  $header++;
}
