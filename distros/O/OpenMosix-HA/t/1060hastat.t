#!/usr/bin/perl -w
# vim:set syntax=perl:
use strict;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 9 }

use OpenMosix::HA;
# use Data::Dump qw(dump);

my $ha = new OpenMosix::HA
(
 hpcbase=>"t/scratch/proc/hpc",
 clinit_s=>"t/scratch/var/mosix-ha/clinit.s",
 mfsbase=>"t/scratch/mfs1",
 mwhois=>'echo This is MOSIX \#1',
 stomith=>\&stomith
);

ok $ha;
my ($hastat) = $ha->hastat(1,2,3);
# graph($hastat);
ok $hastat->{"foo"}{1}{level} eq "start";
ok $hastat->{"foo"}{1}{state} eq "DONE";
ok $hastat->{"bar"}{1}{level} eq "start";
ok $hastat->{"bar"}{1}{state} eq "DONE";
ok $hastat->{"bar"}{2}{level} eq "stop";
ok $hastat->{"bar"}{2}{state} eq "RUNNING";
ok $hastat->{"baz"}{2}{level} eq "test";
ok $hastat->{"baz"}{2}{state} eq "PASSED";


