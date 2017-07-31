#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Pg::Queue' ) || print "Bail out!\n";
}

diag( "Testing Pg::Queue $Pg::Queue::VERSION, Perl $], $^X" );
