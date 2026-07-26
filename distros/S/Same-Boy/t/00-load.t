#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Same::Boy' ) || print "Bail out!\n";
}

diag( "Testing Same::Boy $Same::Boy::VERSION, Perl $], $^X" );
