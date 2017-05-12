#!perl -T
use 5.14.0;
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('Term::ANSITable') || print "Bail out!\n";
}

diag("Testing Term::ANSITable $Term::ANSITable::VERSION, Perl $], $^X");
