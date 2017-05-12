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
my ($hastat,$stomlist) = $ha->hastat(1,2,3);
$ha->stomscan($stomlist);
# graph($hastat);
ok ! stomck(1);
ok stomck(2);
ok ! stomck(3);
ok ! stomck(4);
`touch t/scratch/mfs1/2/var/mosix-ha/clstat`;
stomreset();
($hastat,$stomlist) = $ha->hastat(1,2,3);
$ha->stomscan($stomlist);
ok ! stomck(1);
ok ! stomck(2);
ok ! stomck(3);
ok ! stomck(4);

