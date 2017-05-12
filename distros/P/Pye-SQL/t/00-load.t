#!/usr/bin/env perl

use Test::More tests => 1;

BEGIN {
	use_ok('Pye::SQL') || print "Bail out!\n";
}

diag("Testing Pye::SQL $Pye::SQL::VERSION, Perl $], $^X");
