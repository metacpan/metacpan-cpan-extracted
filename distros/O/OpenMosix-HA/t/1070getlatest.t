#!/usr/bin/perl -w
# vim:set syntax=perl:
use strict;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 8 }

use OpenMosix::HA;
# use Data::Dump qw(dump);

my $ha;

$ha = new OpenMosix::HA
(
 hpcbase=>"t/scratch/proc/hpc",
 clinit_s=>"t/scratch/var/mosix-ha/clinit.s",
 mfsbase=>"t/scratch/mfs1",
 mwhois=>'echo This is MOSIX \#2'
);
ok $ha->getlatest("hactl",1,2,3);
ok ! $ha->getlatest("hactl",1,2,3);

$ha = new OpenMosix::HA
(
 hpcbase=>"t/scratch/proc/hpc",
 clinit_s=>"t/scratch/var/mosix-ha/clinit.s",
 mfsbase=>"t/scratch/mfs1",
 mwhois=>'echo This is MOSIX \#3'
);
ok $ha->getlatest("clstat",1,2,3);
ok ! $ha->getlatest("clstat",1,2,3);

$ha = new OpenMosix::HA
(
 hpcbase=>"t/scratch/proc/hpc",
 clinit_s=>"t/scratch/var/mosix-ha/clinit.s",
 mfsbase=>"t/scratch/mfs1",
 mwhois=>'echo This is MOSIX \#2'
);
ok ! $ha->getlatest("clstat",1,2,3);
ok ! $ha->getlatest("clstat",1,2,3);

$ha = new OpenMosix::HA
(
 hpcbase=>"t/scratch/proc/hpc",
 clinit_s=>"t/scratch/var/mosix-ha/clinit.s",
 mfsbase=>"t/scratch/mfs1",
 mwhois=>'echo This is MOSIX \#1'
);
ok $ha->getlatest("clstat",1,2,3);
ok ! $ha->getlatest("clstat",1,2,3);


