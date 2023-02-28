#!perl

use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'OpenAI::API' ) || print "Bail out!\n";
}

diag( "Testing OpenAI::API $OpenAI::API::VERSION, Perl $], $^X" );
