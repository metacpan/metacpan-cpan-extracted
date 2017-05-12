#! /usr/bin/perl -w
#*********************************************************************
#*** t/04LBSingleton.t
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: 04LBSingleton.t,v 1.1 2002-07-08 20:30:28 mws Exp $
#*********************************************************************
use strict;
use Test;

use ResourcePool;
use ResourcePool::LoadBalancer;

BEGIN { plan tests => 1; };

my $p1 = ResourcePool::LoadBalancer->new("lb1");
my $p2 = ResourcePool::LoadBalancer->new("lb1");
my $p3 = ResourcePool::LoadBalancer->new("lb2");
my $p4 = ResourcePool::LoadBalancer->new("lb2");
my $p5 = ResourcePool::LoadBalancer->new("lb1");

ok(($p1 == $p2) && ($p1 == $p5) && ($p3 == $p4) && ($p1 != $p3));
