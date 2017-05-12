#!/usr/bin/perl
require 5.00561;

use ExtUtils::testlib;
# use Devel::Peek;
use Data::Dumper;
use Rx;

unless ($rx = shift) {
  print "Regex> ";
  $rx = <>;
  chomp $rx;
}
my $bc = Rx::rxbytecode($rx, '');
for $c (split //, $bc) {
  printf "%6d  ", $i if $i % 4 == 0;
  printf "%3d ", ord($c);
  print "\n" if ++$i % 4 == 0;
}

print "\n";
