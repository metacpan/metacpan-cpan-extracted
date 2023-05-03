#!perl
use 5.10.1;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'SVN::Rami' ) || print "Bail out!\n";
}

diag( "Testing SVN::Rami $SVN::Rami::VERSION, Perl $], $^X" );
