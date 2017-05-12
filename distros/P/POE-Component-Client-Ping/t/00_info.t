#!/usr/bin/perl
# vim: ts=2 sw=2 filetype=perl expandtab
use warnings;
use strict;

use Test::More tests => 2;
use_ok('POE');
use_ok('POE::Component::Client::Ping');

# idea from Test::Harness, thanks!
diag(
  "Testing POE $POE::VERSION, ",
  "Perl $], ",
  "$^X on $^O"
);
