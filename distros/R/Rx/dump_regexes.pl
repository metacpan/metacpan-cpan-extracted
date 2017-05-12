#!/usr/bin/perl
require 5.00561;

use ExtUtils::testlib;
# use Devel::Peek;
use Data::Dumper;
use Rx;

unless ($rx = shift) {
  print "Regex> " if -t;
  $rx = <STDIN>;
  chomp $rx;
}


$s = Rx::rxdump($rx);
print Dumper($s);



