#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1; # last test to print

BEGIN {
   use_ok('Sidekick::Check');
}

diag("Testing Sample::Module $Sample::Module::VERSION");

# vim:ts=4:sw=4:syn=perl
