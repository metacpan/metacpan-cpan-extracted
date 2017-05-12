#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1; # last test to print

BEGIN {
   use_ok('Sidekick::Check::Plugin::Filled');
}

diag("Testing Sidekick::Check::Plugin::Filled $Sidekick::Check::Plugin::Filled::VERSION");

# vim:ts=4:sw=4:syn=perl
