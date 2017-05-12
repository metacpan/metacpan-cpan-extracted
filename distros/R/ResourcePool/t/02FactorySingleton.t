#! /usr/bin/perl -w
#*********************************************************************
#*** t/02FactorySingleton.t
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: 02FactorySingleton.t,v 1.11 2013-04-16 10:14:44 mws Exp $
#*********************************************************************
use strict;
use Test;

use ResourcePool::Factory;

BEGIN {	plan tests => 1;};


my $f1 = ResourcePool::Factory->new("hostname1");
my $f2 = ResourcePool::Factory->new("hostname1");
my $f3 = ResourcePool::Factory->new("hostname2");
my $f4 = ResourcePool::Factory->new("hostname2");
my $f5 = ResourcePool::Factory->new("hostname1");
ok(($f1->singleton() == $f2->singleton()) && ($f1->singleton() == $f5->singleton()) 
  && ($f3->singleton() == $f4->singleton()) && ($f1->singleton() != $f3->singleton()));
