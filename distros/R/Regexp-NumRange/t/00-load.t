#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Regexp::NumRange') || print "Bail out!\n";
}

diag("Testing Regexp::NumRange $Regexp::NumRange::VERSION, Perl $], $^X");
