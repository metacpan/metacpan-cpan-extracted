#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mir::FileHandler' ) || print "Bail out!\n";
}

diag( "Testing Mir::FileHandler $Mir::FileHandler::VERSION, Perl $], $^X" );
