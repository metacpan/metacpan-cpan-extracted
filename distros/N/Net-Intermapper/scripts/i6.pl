#!/usr/bin/perl

use lib qw(Net/Intermapper/lib);
use Net::Intermapper;
use Data::Dumper;
use warnings;
use strict;

my $intermapper = Net::Intermapper->new(hostname=>"10.0.0.1", username=>"admin", password=>"nmsadmin");
my %users = % { $intermapper->users };
my @usernames = keys %users;
my $header = 0;
for my $user (@usernames)
{ print $users{$user}->header unless $header;
  print $users{$user}->toCSV;
  $header++;
}
