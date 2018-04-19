#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Safe::Hole');
}

diag("Testing Safe::Hole $Safe::Hole::VERSION, Perl $], $^X");
