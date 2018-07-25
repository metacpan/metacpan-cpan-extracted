#!perl
use 5.01000;
use Test::Most;

plan tests => 1;

BEGIN {
    use_ok('Music::Voss') || print "Bail out!\n";
}

diag("Testing Music::Voss $Music::Voss::VERSION, Perl $], $^X");
