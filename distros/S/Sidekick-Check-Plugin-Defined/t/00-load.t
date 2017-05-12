#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1; # last test to print

BEGIN {
   use_ok('Sidekick::Check::Plugin::Defined');
}

diag("Sidekick::Check::Plugin::Defined $Sidekick::Check::Plugin::Defined::VERSION");

# vim:ts=4:sw=4:syn=perl
