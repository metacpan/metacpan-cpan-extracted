#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'RundeckAPI' ) || print "Bail out!\n";
}

diag( "Testing RundeckAPI $RundeckAPI::VERSION, Perl $], $^X" );
