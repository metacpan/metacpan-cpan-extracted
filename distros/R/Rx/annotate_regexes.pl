#!/usr/bin/perl
require 5.00561;

use ExtUtils::testlib;
# use Devel::Peek;
use Data::Dumper;
use Rx;

unless (defined($rc = shift())) {
  print "Regex> ";
  chomp($rc = <STDIN>);
}


$s = Rx::pl_instrument($rc, '');
print Dumper($s);
