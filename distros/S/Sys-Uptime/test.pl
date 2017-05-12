#!/usr/bin/perl -w

use strict;
use lib ('/home/wim/Scripts/cpuload');
use Sys::Uptime;

my $nbrcpu = Sys::Uptime->cpunbr;
my @load   = Sys::Uptime->loadavg;
my $uptime = Sys::Uptime->uptime;
my $users  = Sys::Uptime->users;

print "CPU's installed:                $nbrcpu\n";
print "Load average (1min 5min 15min): @load\n";
print "Systems uptime (seconds):       $uptime\n";
print "Users logged on:                $users\n";
