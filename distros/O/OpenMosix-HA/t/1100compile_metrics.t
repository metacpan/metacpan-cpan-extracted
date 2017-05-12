#!/usr/bin/perl -w
# vim:set syntax=perl:
use strict;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 119 }

use OpenMosix::HA;
# use Data::Dump qw(dump);

my $ha;
my $hastat;
my $hactl;
my %metric;

$ha = new OpenMosix::HA
(
 hpcbase=>"t/scratch/proc/hpc",
 clinit_s=>"t/scratch/var/mosix-ha/clinit.s",
 mfsbase=>"t/scratch/mfs1",
 mwhois=>'echo This is MOSIX \#1'
);
ok($ha);
($hastat)=$ha->hastat(1,2,3);
ok $hastat;
$hactl=$ha->gethactl(1,2,3);
ok $hactl;

%metric = $ha->compile_metrics($hastat,$hactl,"foo");
ok $metric{isactive};
ok $metric{islocal};
ok $metric{instances},1;
ok ! $metric{inconflict};
ok ! $metric{planned};
ok ! $metric{passed};
ok ! $metric{failed};
ok ! $metric{chlevel};
ok ! $metric{needplan};
ok ! $metric{deleted};

%metric = $ha->compile_metrics($hastat,$hactl,"bar");
ok $metric{isactive};
ok $metric{islocal};
ok $metric{instances},2;
ok $metric{inconflict};
ok ! $metric{planned};
ok ! $metric{passed};
ok ! $metric{failed};
ok $metric{chlevel};
ok ! $metric{needplan};
ok ! $metric{deleted};

%metric = $ha->compile_metrics($hastat,$hactl,"pln");
ok $metric{isactive};
ok $metric{islocal};
ok $metric{instances},1;
ok ! $metric{inconflict};
ok $metric{planned};
ok ! $metric{passed};
ok ! $metric{failed};
ok $metric{chlevel};
ok ! $metric{needplan};
ok ! $metric{deleted};

%metric = $ha->compile_metrics($hastat,$hactl,"bad");
ok $metric{isactive};
ok $metric{islocal};
ok $metric{instances},1;
ok ! $metric{inconflict};
ok ! $metric{planned};
ok ! $metric{passed};
ok $metric{failed};
ok $metric{chlevel};
ok ! $metric{needplan};
ok ! $metric{deleted};

%metric = $ha->compile_metrics($hastat,$hactl,"new");
ok ! $metric{isactive};
ok ! $metric{islocal};
ok ! $metric{instances};
ok ! $metric{inconflict};
ok ! $metric{planned};
ok ! $metric{passed};
ok ! $metric{failed};
ok ! $metric{chlevel};
ok $metric{needplan};
ok ! $metric{deleted};

%metric = $ha->compile_metrics($hastat,$hactl,"del");
ok $metric{isactive};
ok $metric{islocal};
ok $metric{instances},1;
ok ! $metric{inconflict};
ok ! $metric{planned};
ok ! $metric{passed};
ok ! $metric{failed};
ok ! $metric{chlevel};
ok ! $metric{needplan};
ok $metric{deleted};

$ha = new OpenMosix::HA
(
 hpcbase=>"t/scratch/proc/hpc",
 clinit_s=>"t/scratch/var/mosix-ha/clinit.s",
 mfsbase=>"t/scratch/mfs1",
 mwhois=>'echo This is MOSIX \#2'
);
ok($ha);
($hastat)=$ha->hastat(1,2,3);
ok $hastat;
$hactl=$ha->gethactl(1,2,3);
ok $hactl;

%metric = $ha->compile_metrics($hastat,$hactl,"foo");
ok $metric{isactive};
ok ! $metric{islocal};
ok $metric{instances},1;
ok ! $metric{inconflict};
ok ! $metric{planned};
ok ! $metric{passed};
ok ! $metric{failed};
ok ! $metric{chlevel};
ok ! $metric{needplan};
ok ! $metric{deleted};

%metric = $ha->compile_metrics($hastat,$hactl,"bar");
ok $metric{isactive};
ok $metric{islocal};
ok $metric{instances},2;
ok $metric{inconflict};
ok ! $metric{planned};
ok ! $metric{passed};
ok ! $metric{failed};
ok $metric{chlevel};
ok ! $metric{needplan};
ok ! $metric{deleted};

%metric = $ha->compile_metrics($hastat,$hactl,"baz");
ok $metric{isactive};
ok $metric{islocal};
ok $metric{instances},1;
ok ! $metric{inconflict};
ok ! $metric{planned};
ok $metric{passed};
ok ! $metric{failed};
ok $metric{chlevel};
ok ! $metric{needplan};
ok ! $metric{deleted};

$ha = new OpenMosix::HA
(
 hpcbase=>"t/scratch/proc/hpc",
 clinit_s=>"t/scratch/var/mosix-ha/clinit.s",
 mfsbase=>"t/scratch/mfs1",
 mwhois=>'echo This is MOSIX \#3'
);
ok($ha);
($hastat)=$ha->hastat(1,2,3);
ok $hastat;
$hactl=$ha->gethactl(1,2,3);
ok $hactl;

%metric = $ha->compile_metrics($hastat,$hactl,"foo");
ok $metric{isactive};
ok ! $metric{islocal};
ok $metric{instances},1;
ok ! $metric{inconflict};
ok ! $metric{planned};
ok ! $metric{passed};
ok ! $metric{failed};
ok ! $metric{chlevel};
ok ! $metric{needplan};
ok ! $metric{deleted};

%metric = $ha->compile_metrics($hastat,$hactl,"bar");
ok $metric{isactive};
ok ! $metric{islocal};
ok $metric{instances},2;
ok ! $metric{inconflict};
ok ! $metric{planned};
ok ! $metric{passed};
ok ! $metric{failed};
ok ! $metric{chlevel};
ok ! $metric{needplan};
ok ! $metric{deleted};

