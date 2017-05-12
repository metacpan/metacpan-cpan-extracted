#!perl -T

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;


BEGIN
{
	use_ok( 'String::InterpolatedVariables' );
}

diag( "Testing String::InterpolatedVariables $String::InterpolatedVariables::VERSION, Perl $], $^X" );
