#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Payment::CCAvenue::NonSeamless' ) || print "Bail out!\n";
}

diag( "Testing Net::Payment::CCAvenue::NonSeamless $Net::Payment::CCAvenue::NonSeamless::VERSION, Perl $], $^X" );
