#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Mojo::Google') || print "Bail out!\n";
}

diag("Testing Mojo::Google $Mojo::Google::VERSION, Perl $], $^X");
