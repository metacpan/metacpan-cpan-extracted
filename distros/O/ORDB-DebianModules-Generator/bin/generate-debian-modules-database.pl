#!/usr/bin/perl

use ORDB::DebianModules::Generator;

if(scalar(@ARGV) != 1) {
  print "Usage: $0 output.db\n";
  exit(1);
}

ORDB::DebianModules::Generator::save($ARGV[0]);
