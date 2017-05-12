#!/usr/bin/perl -w
# vim:set syntax=perl:
use strict;
use warnings;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 17 }

use OpenMosix::HA;
use Data::Dump qw(dump);

my %ha;
my @node=(1,2,3);
my $tm=40;

# start daemons 
my @child;
for my $node (@node)
{
  my $ha= new OpenMosix::HA
    (
     hpcbase=>"t/scratch/proc/hpc",
     clinit_s=>"t/scratch/var/mosix-ha/clinit.$node.s",
     mfsbase=>"t/scratch/mfs1",
     mwhois=>'echo This is MOSIX \#'.$node
    );
  # warn $ha->{mwhois};
  $ha->clinit();
  my $child;
  unless ($child=fork())
  {
    $ha->monitor($tm*10);
    # $ha->{clinit}->shutdown;
    # waitdown();
    exit;
  }
  $ha{$node}=$ha;
  push @child, $child;
}

# do tests
run(1) while ! -f "t/scratch/mfs1/1/var/mosix-ha/clstat";
run(1) while ! -f "t/scratch/mfs1/1/var/mosix-ha/hastat";
run(1);
ok waitgstop($ha{1},"del",$tm,'any');
ok waitgstat($ha{1},"bad","test","FAILED",$tm*2,'any');
ok waitgstat($ha{1},"foo","start","DONE",$tm*2,'any');
ok waitgstat($ha{1},"bar","2","DONE",$tm,'any');
ok waitgstat($ha{1},"baz","start","DONE",$tm,'any');
ok waitgstat($ha{1},"new","start","DONE",$tm,'any');

`echo "del start" > t/scratch/mfs1/1/var/mosix-ha/hactl`;
run(1);
ok waitgstat($ha{1},"del","plan","DONE",$tm,'any');
ok waitgstat($ha{1},"del","test","DONE",$tm*2,'any');
ok waitgstat($ha{1},"del","start","DONE",$tm,'any');
ok waitgstop($ha{1},"bad",$tm,'any');
ok waitgstop($ha{1},"foo",$tm,'any');
ok waitgstop($ha{1},"bar",$tm,'any');
ok waitgstop($ha{1},"baz",$tm,'any');
ok waitgstop($ha{1},"new",$tm,'any');

`echo "foo start" >> t/scratch/mfs1/1/var/mosix-ha/hactl`;
run(1);
ok waitgstat($ha{1},"foo","plan","DONE",$tm,'any');
ok waitgstat($ha{1},"foo","test","DONE",$tm,'any');
ok waitgstat($ha{1},"foo","start","DONE",$tm,'any');

# my ($hastat)=$ha{1}->hastat(@node);
# warn dump $hastat;


# kill monitors
kill 9, @child;
# kill clinit daemons
$ha{$_}->{clinit}->shutdown for (@node);

waitdown();

__END__

my $node1 = new OpenMosix::HA
(
 hpcbase=>"t/scratch/proc/hpc",
 clinit_s=>"t/scratch/var/mosix-ha/clinit.s",
 mfsbase=>"t/scratch/mfs1",
 mwhois=>'echo This is MOSIX \#1'
);
ok($node1);

my $node2 = new OpenMosix::HA
(
 hpcbase=>"t/scratch/proc/hpc",
 clinit_s=>"t/scratch/var/mosix-ha/clinit.s",
 mfsbase=>"t/scratch/mfs1",
 mwhois=>'echo This is MOSIX \#2'
);
ok($node2);

my $node3 = new OpenMosix::HA
(
 hpcbase=>"t/scratch/proc/hpc",
 clinit_s=>"t/scratch/var/mosix-ha/clinit.s",
 mfsbase=>"t/scratch/mfs1",
 mwhois=>'echo This is MOSIX \#3'
);
ok($node3);

while(1)
{
  $node1->monitor(1);
  $node2->monitor(1);
  $node3->monitor(1);
  run(1);
}

$node1->{clinit}->shutdown;
$node2->{clinit}->shutdown;
$node3->{clinit}->shutdown;
waitdown();
