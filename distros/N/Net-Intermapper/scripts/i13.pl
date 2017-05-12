#!/usr/bin/perl

use lib qw(Net/Intermapper/lib);
use Net::Intermapper;
use Net::Intermapper::User;

use Data::Dumper;
use warnings;
use strict;

# Adding and updating requires a different username and password
# Use the user you configured for the web-based configuration
my $intermapper = Net::Intermapper->new(hostname=>"10.0.0.1", username=>"admin", password=>"nmsadmin", format=>"tab");
my $user = Net::Intermapper::User->new(Name=>"testuser", Password=>"Test12345");

$intermapper->create($user);
$user = $intermapper->users->{"testuser"};
print "OK\n" if $user->Password eq "Test12345";

$user->Password("Foobar123");
$intermapper->update($user);
$user = $intermapper->users->{"testuser"};
print "OK\n" if $user->Password eq "Foobar123";
