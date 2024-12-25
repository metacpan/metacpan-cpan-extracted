#!/usr/bin/env perl
use lib './lib';
use Proc::Forkmap;

$Proc::Forkmap::MAX_PROCS = 4;

sub foo {
  my $n = shift;
  sleep $n;
  print "slept $n seconds\n";
}

my @x = (1, 4, 2);

forkmap { foo($_) } @x;
