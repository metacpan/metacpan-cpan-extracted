#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Sub::Deprecate' ) || print "Bail out!\n";
}

diag( "Testing Sub::Deprecate $Sub::Deprecate::VERSION, Perl $], $^X" );
