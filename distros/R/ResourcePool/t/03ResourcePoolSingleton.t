#! /usr/bin/perl -w
#*********************************************************************
#*** t/03ResourcePoolSingleton.t
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: 03ResourcePoolSingleton.t,v 1.7 2003-01-04 11:20:31 mws Exp $
#*********************************************************************
use strict;
use Test;
use ResourcePool;
use ResourcePool::Factory;

BEGIN { plan tests => 2; };

my ($f1, $f2, $f3);
$f1 = new ResourcePool::Factory->new("hostname1");
$f2 = new ResourcePool::Factory->new("hostname2");

my $p1 = ResourcePool->new($f1);
my $p2 = ResourcePool->new($f1);
my $p3 = ResourcePool->new($f2);
my $p4 = ResourcePool->new($f2);
my $p5 = ResourcePool->new($f1);
ok(($p1 == $p2) && ($p1 == $p5) && ($p3 == $p4) && ($p1 != $p3));

## seperate test, which checks if ResourcePool uses $factory->singleton()
$f1 = new ResourcePool::Factory->new("hostname1_new");
$f2 = new ResourcePool::Factory->new("hostname2_new");
$f3 = new ResourcePool::Factory->new("hostname1_new");

$p1 = ResourcePool->new($f1);
$p2 = ResourcePool->new($f1);
$p3 = ResourcePool->new($f2);
$p4 = ResourcePool->new($f2);
$p5 = ResourcePool->new($f3);
ok(($p1 == $p2) && ($p1 == $p5) && ($p3 == $p4) && ($p1 != $p3));

# TODO, make ResourcePool handle different options with the same internal Pool
