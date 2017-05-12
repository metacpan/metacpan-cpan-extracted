#! /usr/bin/perl -w
# Original ResourcePool::Resource::Net::LDAP:
#*********************************************************************
#*** t/02FactorySingleton.t
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*********************************************************************

use strict;
use Test;
use Net::LDAPapi;
use ResourcePool::Factory::Net::LDAPapi;

BEGIN {	plan tests => 7;};

my ($f1, $f2, $f3, $f4, $f5);

$f1 = ResourcePool::Factory::Net::LDAPapi->new("hostname1");
$f2 = ResourcePool::Factory::Net::LDAPapi->new("hostname1");
$f3 = ResourcePool::Factory::Net::LDAPapi->new("hostname2");
$f4 = ResourcePool::Factory::Net::LDAPapi->new("hostname2");
$f5 = ResourcePool::Factory::Net::LDAPapi->new("hostname1");
ok(($f1->singleton() == $f2->singleton()) && ($f1->singleton() == $f5->singleton()) 
  && ($f3->singleton() == $f4->singleton()) && ($f1->singleton() != $f3->singleton()));

$f1 = ResourcePool::Factory::Net::LDAPapi->new("hostname");
$f2 = ResourcePool::Factory::Net::LDAPapi->new("hostname");
$f3 = ResourcePool::Factory::Net::LDAPapi->new("hostname", [dn => 'dn', password => 'pass']);
$f4 = ResourcePool::Factory::Net::LDAPapi->new("hostname", [dn => 'dn', password => 'pass']);
$f5 = ResourcePool::Factory::Net::LDAPapi->new("hostname");
ok(($f1->singleton() == $f2->singleton()) && ($f1->singleton() == $f5->singleton()) 
  && ($f3->singleton() == $f4->singleton()) && ($f1->singleton() != $f3->singleton()));

$f1 = ResourcePool::Factory::Net::LDAPapi->new("hostname", [dn => 'dn', password => 'pass1']);
$f2 = ResourcePool::Factory::Net::LDAPapi->new("hostname", [dn => 'dn', password => 'pass1']);
$f3 = ResourcePool::Factory::Net::LDAPapi->new("hostname", [dn => 'dn', password => 'pass2']);
$f4 = ResourcePool::Factory::Net::LDAPapi->new("hostname", [dn => 'dn', password => 'pass2']);
$f5 = ResourcePool::Factory::Net::LDAPapi->new("hostname", [dn => 'dn', password => 'pass1']);
ok(($f1->singleton() == $f2->singleton()) && ($f1->singleton() == $f5->singleton()) 
  && ($f3->singleton() == $f4->singleton()) && ($f1->singleton() != $f3->singleton()));

$f1 = ResourcePool::Factory::Net::LDAPapi->new("hostname", [], [port => 10000]);
$f2 = ResourcePool::Factory::Net::LDAPapi->new("hostname", [], [port => 10000]);
$f3 = ResourcePool::Factory::Net::LDAPapi->new("hostname", [], [port => 20000]);
$f4 = ResourcePool::Factory::Net::LDAPapi->new("hostname", [], [port => 20000]);
$f5 = ResourcePool::Factory::Net::LDAPapi->new("hostname", [], [port => 10000]);
ok(($f1->singleton() == $f2->singleton()) && ($f1->singleton() == $f5->singleton()) 
  && ($f3->singleton() == $f4->singleton()) && ($f1->singleton() != $f3->singleton()));

$f1 = ResourcePool::Factory::Net::LDAPapi->new("hostname_new");
$f2 = ResourcePool::Factory::Net::LDAPapi->new("hostname_new");
$f3 = ResourcePool::Factory::Net::LDAPapi->new("hostname_new");
$f3->bind(dn => 'dn', password => 'pass');
$f4 = ResourcePool::Factory::Net::LDAPapi->new("hostname_new");
$f4->bind(dn => 'dn', password => 'pass');
$f5 = ResourcePool::Factory::Net::LDAPapi->new("hostname_new");
ok(($f1->singleton() == $f2->singleton()) && ($f1->singleton() == $f5->singleton()) 
  && ($f3->singleton() == $f4->singleton()) && ($f1->singleton() != $f3->singleton()));

$f1 = ResourcePool::Factory::Net::LDAPapi->new("hostname_new");
$f1->bind(dn => 'dn', password => 'pass1');
$f2 = ResourcePool::Factory::Net::LDAPapi->new("hostname_new");
$f2->bind(dn => 'dn', password => 'pass1');
$f3 = ResourcePool::Factory::Net::LDAPapi->new("hostname_new");
$f3->bind(dn => 'dn', password => 'pass2');
$f4 = ResourcePool::Factory::Net::LDAPapi->new("hostname_new");
$f4->bind(dn => 'dn', password => 'pass2');
$f5 = ResourcePool::Factory::Net::LDAPapi->new("hostname_new");
$f5->bind(dn => 'dn', password => 'pass1');
ok(($f1->singleton() == $f2->singleton()) && ($f1->singleton() == $f5->singleton()) 
  && ($f3->singleton() == $f4->singleton()) && ($f1->singleton() != $f3->singleton()));

$f1 = ResourcePool::Factory::Net::LDAPapi->new("hostname_new", port => 10000);
$f2 = ResourcePool::Factory::Net::LDAPapi->new("hostname_new", port => 10000);
$f3 = ResourcePool::Factory::Net::LDAPapi->new("hostname_new", port => 20000);
$f4 = ResourcePool::Factory::Net::LDAPapi->new("hostname_new", port => 20000);
$f5 = ResourcePool::Factory::Net::LDAPapi->new("hostname_new", port => 10000);
ok(($f1->singleton() == $f2->singleton()) && ($f1->singleton() == $f5->singleton()) 
  && ($f3->singleton() == $f4->singleton()) && ($f1->singleton() != $f3->singleton()));
