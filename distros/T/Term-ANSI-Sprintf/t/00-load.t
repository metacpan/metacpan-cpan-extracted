#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Term::ANSI::Sprintf' ) || print "Bail out!\n";
}

diag( "Testing Term::ANSI::Sprintf $Term::ANSI::Sprintf::VERSION, Perl $], $^X" );
