#!perl
use 5.010000;
use strict;
use warnings FATAL => 'all';
use Test::Most;

plan tests => 2;

BEGIN {
  use_ok('Music::Canon') || print "Bail out!\n";
  my $mc = Music::Canon->new;
  isa_ok( $mc, 'Music::Canon' ) || print "Bail out!\n";
}

diag("Testing Music::Canon $Music::Canon::VERSION, Perl $], $^X");
