#! /usr/bin/perl -w
#*********************************************************************
#*** t/02FactorySingleton.t
#*** Copyright (c) 2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: 02FactorySingleton.t,v 1.2 2003-02-22 17:07:48 mws Exp $
#*********************************************************************
use strict;
use Test;

use SOAP::Lite;
use ResourcePool::Factory::SOAP::Lite;

BEGIN { plan tests => 1;};

my ($f1, $f2, $f3, $f4, $f5);

$f1 = ResourcePool::Factory::SOAP::Lite->new("proxy1");
$f2 = ResourcePool::Factory::SOAP::Lite->new("proxy1");
$f3 = ResourcePool::Factory::SOAP::Lite->new("proxy2");
$f4 = ResourcePool::Factory::SOAP::Lite->new("proxy2");
$f5 = ResourcePool::Factory::SOAP::Lite->new("proxy1");
ok( ($f1->singleton() == $f2->singleton()) 
 && ($f1->singleton() == $f5->singleton())
 && ($f3->singleton() == $f4->singleton()) 
 && ($f1->singleton() != $f3->singleton())
);

