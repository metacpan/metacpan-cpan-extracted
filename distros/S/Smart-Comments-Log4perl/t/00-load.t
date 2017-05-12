#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Smart::Comments::Log4perl' ) || print "Bail out!\n";
}

diag( "Testing Smart::Comments::Log4perl $Smart::Comments::Log4perl::VERSION, Perl $], $^X" );
