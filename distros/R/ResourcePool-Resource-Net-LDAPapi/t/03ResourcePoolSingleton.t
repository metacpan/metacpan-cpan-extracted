#! /usr/bin/perl -w
#*********************************************************************
#*** t/03ResourcePoolSingleton.t
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: 03ResourcePoolSingleton.t,v 1.1 2002/12/22 15:15:38 mws Exp $
#*********************************************************************
use strict;
use Test;
use Net::LDAPapi;
use ResourcePool;
use ResourcePool::Factory::Net::LDAPapi;

BEGIN { plan tests => 2; };

my ($f1, $f2, $f3);
my ($p1, $p2, $p3, $p4, $p5);

$f1 = new ResourcePool::Factory::Net::LDAPapi->new("hostname1");
$f2 = new ResourcePool::Factory::Net::LDAPapi->new("hostname2");

$p1 = ResourcePool->new($f1);
$p2 = ResourcePool->new($f1);
$p3 = ResourcePool->new($f2);
$p4 = ResourcePool->new($f2);
$p5 = ResourcePool->new($f1);
ok(($p1 == $p2) && ($p1 == $p5) && ($p3 == $p4) && ($p1 != $p3));

$f1 = new ResourcePool::Factory::Net::LDAPapi->new("hostname1_new");
$f2 = new ResourcePool::Factory::Net::LDAPapi->new("hostname2_new");
$f3 = new ResourcePool::Factory::Net::LDAPapi->new("hostname1_new");

$p1 = ResourcePool->new($f1);
$p2 = ResourcePool->new($f1);
$p3 = ResourcePool->new($f2);
$p4 = ResourcePool->new($f2);
$p5 = ResourcePool->new($f3);
ok(($p1 == $p2) && ($p1 == $p5) && ($p3 == $p4) && ($p1 != $p3));
