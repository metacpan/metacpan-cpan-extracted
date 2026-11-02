#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Pipe::Declare' ) || print "Bail out!\n";
}

diag( "Testing Pipe::Declare $Pipe::Declare::VERSION, Perl $], $^X" );
