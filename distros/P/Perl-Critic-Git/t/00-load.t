#!perl -T

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;


BEGIN
{
	use_ok( 'Perl::Critic::Git' );
}

diag( "Testing Perl::Critic::Git $Perl::Critic::Git::VERSION, Perl $], $^X" );
