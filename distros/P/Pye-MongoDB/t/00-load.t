#!/usr/bin/env perl

use Test::More tests => 1;

BEGIN {
	use_ok('Pye::MongoDB') || print "Bail out!\n";
}

diag("Testing Pye::MongoDB $Pye::MongoDB::VERSION, Perl $], $^X");
