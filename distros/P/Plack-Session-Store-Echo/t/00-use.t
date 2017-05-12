#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;


BEGIN {
	use_ok 'Plack::Session::Store::Echo' or print("Bail out!\n");
}

diag "Testing Plack::Session::Store::Echo $Plack::Session::Store::Echo::VERSION, Perl $], $^X";
