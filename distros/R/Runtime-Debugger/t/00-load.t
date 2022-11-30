#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Term::ReadLine' ) || print "Bail out!\n";
    use_ok( 'Term::ReadLine::Gnu' ) || print "Bail out!\n";
    use_ok( 'Runtime::Debugger' ) || print "Bail out!\n";
}

diag( "Testing Runtime::Debugger $Runtime::Debugger::VERSION, Perl $], $^X" );
