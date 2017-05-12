#!/usr/bin/perl

use strict;
use warnings;

use Net::Nmsg::Input;
use Net::Nmsg::Output;

my $n = Net::Nmsg::Input ->open('127.0.0.1/8430');
my $o = Net::Nmsg::Output->open('127.0.0.1/9430');

print 'starting...';

my $c = 0;
while (my $m = $n->read()) {
  ++$c;
  print STDERR '.' unless $c % 1000;
  print STDERR $c  unless $c % 10000;
  $o->write($m);
}
