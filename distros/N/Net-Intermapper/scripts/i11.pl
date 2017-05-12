#!/usr/bin/perl

use lib qw(Net/Intermapper/lib);
use Net::Intermapper;
use Net::Intermapper::User;

use Data::Dumper;
use warnings;
use strict;

my $intermapper = Net::Intermapper->new(hostname=>"10.0.0.1", username=>"admin", password=>"nmsadmin");
my $user = Net::Intermapper::User->new(Name=>"testuser", Password=>"Test12345");
print Dumper $intermapper->create($user);
