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
 mwhois=>'echo This is MOSIX \#3'
);

ok($ha);
ok $ha->getcltab(1,2,3);
my $clinit=$ha->clinit();
ok $clinit;
ok $ha->{clinit};
my $rc = eval
{
  my $cltab = $ha->getcltab(1,2,3);
  # XXX check for reread 
  ok $cltab->{foo};
  ok $cltab->{bar};
};
ok $rc;
warn $@ unless $rc;
$ha->{clinit}->shutdown;
waitdown();

# use GraphViz::Data::Grapher;
# my $graph = GraphViz::Data::Grapher->new(%$ha);
# open(F,">/tmp/2.ps") || die $!;
# print F $graph->as_ps;
