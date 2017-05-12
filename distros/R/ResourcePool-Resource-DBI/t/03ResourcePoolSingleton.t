#! /usr/bin/perl -w
#*********************************************************************
#*** t/03ResourcePoolSingleton.t
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: 03ResourcePoolSingleton.t,v 1.1 2002/12/22 14:53:11 mws Exp $
#*********************************************************************
use strict;
use Test;
use DBI;
use ResourcePool;
use ResourcePool::Factory::DBI;

BEGIN { plan tests => 2; };

my ($f1, $f2, $f3);
my ($p1, $p2, $p3, $p4, $p5);

$f1 = new ResourcePool::Factory::DBI->new("DataSource1", "user", "pass");
$f2 = new ResourcePool::Factory::DBI->new("DataSource2", "user", "pass");

$p1 = ResourcePool->new($f1);
$p2 = ResourcePool->new($f1);
$p3 = ResourcePool->new($f2);
$p4 = ResourcePool->new($f2);
$p5 = ResourcePool->new($f1);
ok(($p1 == $p2) && ($p1 == $p5) && ($p3 == $p4) && ($p1 != $p3));

$f1 = new ResourcePool::Factory::DBI->new("DataSource1_new", "user", "pass");
$f2 = new ResourcePool::Factory::DBI->new("DataSource2_new", "user", "pass");
$f3 = new ResourcePool::Factory::DBI->new("DataSource1_new", "user", "pass");

$p1 = ResourcePool->new($f1);
$p2 = ResourcePool->new($f1);
$p3 = ResourcePool->new($f2);
$p4 = ResourcePool->new($f2);
$p5 = ResourcePool->new($f3);
ok(($p1 == $p2) && ($p1 == $p5) && ($p3 == $p4) && ($p1 != $p3));

