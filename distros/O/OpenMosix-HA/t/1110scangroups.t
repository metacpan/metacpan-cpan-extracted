#!/usr/bin/perl -w
# vim:set syntax=perl:
use strict;
use warnings;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 60 }

use OpenMosix::HA;
use Data::Dump qw(dump);
# use Devel::Trace qw(trace);

my $ha;
my $hastat;
my $hactl;
my %metric;
my @node=(1,2,3);

$ha = new OpenMosix::HA
(
 hpcbase=>"t/scratch/proc/hpc",
 clinit_s=>"t/scratch/var/mosix-ha/clinit.s",
 mfsbase=>"t/scratch/mfs1",
 mwhois=>'echo This is MOSIX \#1'
);
ok($ha);
# system("cat t/scratch/mfs1/1/var/mosix-ha/cltab");
#ok $ha->getcltab(@node);
ok $ha->clinit();
ok $ha->{clinit};
`cp -rp t/master/* t/scratch`;
$hactl=$ha->gethactl(@node);
($hastat)=$ha->hastat(@node);
$ha->scangroups($hastat,$hactl);
# bar conflicted with node 2
ok waitgstop($ha,"bar");
($hastat)=$ha->hastat(@node);
$ha->scangroups($hastat,$hactl);
ok waitgstat($ha,"foo","plan","DONE");
ok waitgstat($ha,"new","plan","DONE");
ok waitgstat($ha,"bad","plan","DONE");
ok waitgstop($ha,"bar");
# del removed from hactl
ok waitgstop($ha,"del");
($hastat)=$ha->hastat(@node);
$ha->scangroups($hastat,$hactl);
ok waitgstat($ha,"foo","test","DONE");
ok waitgstat($ha,"new","test","DONE");
ok waitgstat($ha,"bad","test","FAILED");
ok waitgstop($ha,"bar");
ok waitgstop($ha,"del");
($hastat)=$ha->hastat(@node);
$ha->scangroups($hastat,$hactl);
ok waitgstat($ha,"foo","start","DONE");
ok waitgstat($ha,"new","start","DONE");
# bad failed test
ok waitgstop($ha,"bad");
ok waitgstop($ha,"bar");
ok waitgstop($ha,"del");
# system("cat t/scratch/mfs1/1/var/mosix-ha/cltab");
# system("cat t/scratch/mfs1/1/var/mosix-ha/clstat");
# system("cat t/scratch/mfs1/1/var/mosix-ha/hactl");
# system("cat t/scratch/mfs1/1/var/mosix-ha/hastat");
# `rm -rf t/scratch2; find t/scratch -type f | cpio -pudm t/scratch2`;
`tar -cf t/scratch.tar t/scratch/mfs1/*/var/mosix-ha/clstat`;
# system("ps auxw | tail");
$ha->{clinit}->shutdown;
waitdown();
# system("ps auxw | tail");
#system("ps auxw | grep perl | grep -v grep");

$ha = new OpenMosix::HA
(
 hpcbase=>"t/scratch/proc/hpc",
 clinit_s=>"t/scratch/var/mosix-ha/clinit.s",
 mfsbase=>"t/scratch/mfs1",
 mwhois=>'echo This is MOSIX \#2'
);
ok($ha);
#ok $ha->getcltab(@node);
ok $ha->clinit();
ok $ha->{clinit};
# let clinit have a chance to run cleanup()
run(1);
# `cp -rp t/scratch2/* t/scratch`;
`tar -xf t/scratch.tar`;
ok(-f "t/scratch/mfs1/1/var/mosix-ha/clstat");
# system("cat t/scratch/mfs1/1/var/mosix-ha/clstat");
# system("cat t/scratch/mfs1/2/var/mosix-ha/clstat");
# system("cat t/scratch/mfs1/3/var/mosix-ha/clstat");
$hactl=$ha->gethactl(@node);
ok(-f "t/scratch/mfs1/1/var/mosix-ha/clstat");
# system("ps -eafl | grep perl | grep -v grep");
($hastat)=$ha->hastat(@node);
$ha->scangroups($hastat,$hactl);
# system("cat t/scratch/mfs1/2/var/mosix-ha/cltab");
# system("cat t/scratch/mfs1/2/var/mosix-ha/clstat");
# system("cat t/scratch/mfs1/2/var/mosix-ha/hactl");
# system("cat t/scratch/mfs1/2/var/mosix-ha/hastat");
ok waitgstop($ha,"bar");
# foo conflicted with node 1
ok waitgstop($ha,"foo");
ok waitgstat($ha,"baz","start","DONE");
($hastat)=$ha->hastat(@node);
$ha->scangroups($hastat,$hactl);
ok(-f "t/scratch/mfs1/1/var/mosix-ha/clstat");
ok waitgstop($ha,"foo");
ok waitgstat($ha,"bar","plan","DONE");
ok waitgstop($ha,"del");
($hastat)=$ha->hastat(@node);
$ha->scangroups($hastat,$hactl);
ok waitgstop($ha,"foo");
ok waitgstat($ha,"bar","test","DONE");
($hastat)=$ha->hastat(@node);
$ha->scangroups($hastat,$hactl);
ok(-f "t/scratch/mfs1/1/var/mosix-ha/clstat");
ok waitgstop($ha,"foo");
ok waitgstat($ha,"bar","2","DONE");
ok(-f "t/scratch/mfs1/1/var/mosix-ha/clstat");
$ha->{clinit}->shutdown;
waitdown();
ok(-f "t/scratch/mfs1/1/var/mosix-ha/clstat");

$ha = new OpenMosix::HA
(
 hpcbase=>"t/scratch/proc/hpc",
 clinit_s=>"t/scratch/var/mosix-ha/clinit.s",
 mfsbase=>"t/scratch/mfs1",
 mwhois=>'echo This is MOSIX \#3'
);
ok($ha);
ok(-f "t/scratch/mfs1/1/var/mosix-ha/clstat");
#ok $ha->getcltab(@node);
ok(-f "t/scratch/mfs1/1/var/mosix-ha/clstat");
ok $ha->clinit();
ok(-f "t/scratch/mfs1/1/var/mosix-ha/clstat");
ok $ha->{clinit};
$hactl=$ha->gethactl(@node);
($hastat)=$ha->hastat(@node);
$ha->scangroups($hastat,$hactl);
# system("cat t/scratch/mfs1/3/var/mosix-ha/cltab");
# system("cat t/scratch/mfs1/3/var/mosix-ha/clstat");
# system("cat t/scratch/mfs1/3/var/mosix-ha/hactl");
ok(-f "t/scratch/mfs1/1/var/mosix-ha/clstat");
ok waitgstop($ha,"foo");
ok waitgstop($ha,"new");
ok waitgstat($ha,"bar","plan","DONE");
ok waitgstat($ha,"baz","plan","DONE");
ok waitgstat($ha,"bad","plan","DONE");
$hactl=$ha->gethactl(@node);
($hastat)=$ha->hastat(@node);
$ha->scangroups($hastat,$hactl);
ok waitgstop($ha,"foo");
ok waitgstop($ha,"new");
ok waitgstat($ha,"bar","test","DONE");
ok waitgstat($ha,"baz","test","PASSED");
ok waitgstat($ha,"bad","test","FAILED");
$hactl=$ha->gethactl(@node);
($hastat)=$ha->hastat(@node);
$ha->scangroups($hastat,$hactl);
ok waitgstop($ha,"foo");
ok waitgstop($ha,"new");
ok waitgstat($ha,"bar","2","DONE");
ok waitgstat($ha,"baz","start","DONE");
ok waitgstop($ha,"bad");
$ha->{clinit}->shutdown;
waitdown();

