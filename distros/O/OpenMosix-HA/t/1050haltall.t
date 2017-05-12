#!/usr/bin/perl -w
# vim:set syntax=perl:
use strict;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 7 }

use OpenMosix::HA;
# use Data::Dump qw(dump);

my $ha = new OpenMosix::HA
(
 hpcbase=>"t/scratch/proc/hpc",
 clinit_s=>"t/scratch/var/mosix-ha/clinit.s",
 mfsbase=>"t/scratch/mfs1",
 mwhois=>'echo This is MOSIX \#1'
);

ok($ha);
$ha->clinit();
ok $ha->{clinit};
my $clinit=$ha->{clinit};
my $rc = eval
{
  $ha->{clinit}->tell("foo","start");
  $ha->{clinit}->tell("bar","1");
  ok waitstat($clinit,"foo","start","DONE");
  ok waitstat($clinit,"bar",1,"DONE",2);
  $ha->haltall();
  ok waitstat($clinit,"foo","stop","DONE");
  ok waitstat($clinit,"bar","stop","DONE");
};
ok $rc;
warn $@ unless $rc;
$ha->{clinit}->shutdown;
waitdown();

# use GraphViz::Data::Grapher;
# my $graph = GraphViz::Data::Grapher->new(%$ha);
# open(F,">/tmp/2.ps") || die $!;
# print F $graph->as_ps;
