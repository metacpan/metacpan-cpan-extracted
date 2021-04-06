#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;

BEGIN {
  use_ok('Net::IPAM::Tree')          || print "Bail out!\n";
  use_ok('Net::IPAM::Tree::Private') || print "Bail out!\n";
}

done_testing();
