#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
  use_ok('Net::IPAM::Block') || print "Bail out!\n";
}

diag("Testing Net::IPAM::Block $Net::IPAM::Block::VERSION, Perl $], $^X");
