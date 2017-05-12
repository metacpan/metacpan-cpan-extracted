#! /usr/bin/perl -w
#*********************************************************************
#*** t/02FactorySingleton.t
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: 02FactorySingleton.t,v 1.1 2004/04/15 20:44:02 jgsmith Exp $
#*********************************************************************
use strict;
use Test;

use DBI;
use ResourcePool::Factory::Alzabo;

BEGIN {	plan tests => 4;};

my ($f1, $f2, $f3, $f4, $f5);

$f1 = ResourcePool::Factory::Alzabo->new("Schema1", "DataSource1", "user", "pass");
$f2 = ResourcePool::Factory::Alzabo->new("Schema1", "DataSource1", "user", "pass");
$f3 = ResourcePool::Factory::Alzabo->new("Schema1", "DataSource2", "user", "pass");
$f4 = ResourcePool::Factory::Alzabo->new("Schema1", "DataSource2", "user", "pass");
$f5 = ResourcePool::Factory::Alzabo->new("Schema1", "DataSource1", "user", "pass");
ok(($f1->singleton() == $f2->singleton()) && ($f1->singleton() == $f5->singleton()) 
  && ($f3->singleton() == $f4->singleton()) && ($f1->singleton() != $f3->singleton()));

$f1 = ResourcePool::Factory::Alzabo->new("Schema1", "DataSource1", "user", "pass");
$f2 = ResourcePool::Factory::Alzabo->new("Schema2", "DataSource1", "user", "pass");
$f3 = ResourcePool::Factory::Alzabo->new("Schema1", "DataSource2", "user", "pass");
$f4 = ResourcePool::Factory::Alzabo->new("Schema2", "DataSource2", "user", "pass");
$f5 = ResourcePool::Factory::Alzabo->new("Schema1", "DataSource1", "user", "pass");
ok(($f1->singleton() != $f2->singleton()) && ($f1->singleton() == $f5->singleton()) 
  && ($f3->singleton() != $f4->singleton()) && ($f1->singleton() != $f3->singleton()));

$f1 = ResourcePool::Factory::Alzabo->new("Schema", "DataSource", "user1", "pass");
$f2 = ResourcePool::Factory::Alzabo->new("Schema", "DataSource", "user1", "pass");
$f3 = ResourcePool::Factory::Alzabo->new("Schema", "DataSource", "user2", "pass");
$f4 = ResourcePool::Factory::Alzabo->new("Schema", "DataSource", "user2", "pass");
$f5 = ResourcePool::Factory::Alzabo->new("Schema", "DataSource", "user1", "pass");
ok(($f1->singleton() == $f2->singleton()) && ($f1->singleton() == $f5->singleton()) 
  && ($f3->singleton() == $f4->singleton()) && ($f1->singleton() != $f3->singleton()));

$f1 = ResourcePool::Factory::Alzabo->new("Schema", "DataSource", "user", "pass");
$f2 = ResourcePool::Factory::Alzabo->new("Schema", "DataSource", "user", "pass");
$f3 = ResourcePool::Factory::Alzabo->new("Schema", "DataSource", "user", "pass", {AutoCommit => 1});
$f4 = ResourcePool::Factory::Alzabo->new("Schema", "DataSource", "user", "pass", {AutoCommit => 1});
$f5 = ResourcePool::Factory::Alzabo->new("Schema", "DataSource", "user", "pass");
ok(($f1->singleton() == $f2->singleton()) && ($f1->singleton() == $f5->singleton()) 
  && ($f3->singleton() == $f4->singleton()) && ($f1->singleton() != $f3->singleton()));
