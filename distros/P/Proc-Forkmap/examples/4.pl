#!/usr/bin/env perl
use lib './lib';
use strict;
use warnings;
use Proc::Forkmap;

$Proc::Forkmap::IPC = 1;
 
sub foo {
  my $n = shift;
  sleep $n;
  return $n;
}
 
my @x = (1, 4, 2);
my @rs = forkmap { foo($_) } @x;
print "slept $_ seconds\n" for @rs;
