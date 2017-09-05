#!/usr/bin/env perl

use Test::More tests => 4;

BEGIN {
  if ($] ge '5.026') {
    use lib '.';
  }
  use_ok('Net::IPAddress::Util');
  use_ok('Net::IPAddress::Util::Range');
  use_ok('Net::IPAddress::Util::Collection');
  use_ok('Net::IPAddress::Util::Collection::Tie');
}

diag("Testing Net::IPAddress::Util $Net::IPAddress::Util::VERSION, Perl $], $^X");
