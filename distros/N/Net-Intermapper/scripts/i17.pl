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
my $user = Net::Intermapper::User->new(Name=>"testuser", Password=>"Test12345", Groups=>"Read_only,Z-Welcome");
$intermapper->create($user);
$user = $intermapper->users->{'testuser'}; 
print "OK\n" if $user->Name eq "testuser";

my $groups = $user->Groups;
print "OK\n" if $groups eq "Read_only,Z-Welcome";
print "NOK: $groups\n" if $groups ne "Read_only,Z-Welcome";

my @groups = split(/\,/,$groups);
shift @groups; # Remove first, just as an example
$groups = join(",",@groups);
$intermapper->delete($user);
print "OK\n" if !$user;

$user->Groups($groups);
$intermapper->create($user);
print "OK\n" if $user->Name eq "testuser";
