#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'RF::Component' ) || print "Bail out!\n";
}

diag( "Testing RF::Component $RF::Component::VERSION, Perl $], $^X" );
