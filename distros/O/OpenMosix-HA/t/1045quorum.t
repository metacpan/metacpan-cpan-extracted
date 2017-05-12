#!/usr/bin/perl -w
# vim:set syntax=perl:
use strict;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 15 }

use OpenMosix::HA;
# use Data::Dump qw(dump);

my $ha = new OpenMosix::HA
(
 hpcbase=>"t/scratch/proc/hpc",
 clinit_s=>"t/scratch/var/mosix-ha/clinit.s",
 mfsbase=>"t/scratch/mfs1",
 mwhois=>'echo This is MOSIX \#1'
);
ok $ha;

ok $ha->quorum(1,2,3);
ok $ha->quorum(1..10);
ok $ha->quorum(1..7);
ok $ha->quorum(1..6);
ok $ha->quorum(1..10);
ok $ha->quorum(1..6);
ok $ha->quorum(1..20);
ok ! $ha->quorum(1..11);
ok ! $ha->quorum(1..11);
ok $ha->quorum(1..12);
ok $ha->quorum(1..11);
ok ! $ha->quorum(1,2,3);
ok ! $ha->quorum(1,2,3);
ok $ha->quorum(20..40);


