#!perl -T
use 5.010001;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Pg::Reindex' ) || print "Bail out!\n";
}

diag( "Testing Pg::Reindex $Pg::Reindex::VERSION, Perl $], $^X" );
