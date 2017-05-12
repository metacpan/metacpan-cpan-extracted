#!/usr/bin/perl

use lib qw(Net/Intermapper/lib);
use Net::Intermapper;
use Data::Dumper;
use warnings;
use strict;

my $intermapper = Net::Intermapper->new(hostname=>"10.0.0.1", username=>"admin", password=>"nmsadmin");
my %devices = % { $intermapper->devices };
my @devicenames = keys %devices;
my $header = 0;
for my $device (@devicenames)
{ print $devices{$device}->header unless $header;
  print $devices{$device}->toCSV;
  $header++;
}
