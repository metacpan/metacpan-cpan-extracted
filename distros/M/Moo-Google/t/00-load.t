#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Moo::Google') || print "Bail out!\n";
}

diag("Testing Moo::Google $Moo::Google::VERSION, Perl $], $^X");
