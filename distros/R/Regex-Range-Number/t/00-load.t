#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Regex::Range::Number' ) || print "Bail out!\n";
}

diag( "Testing Regex::Range::Number $Regex::Range::Number::VERSION, Perl $], $^X" );
