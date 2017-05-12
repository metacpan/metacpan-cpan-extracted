#!perl -T

use strict;
use warnings;


use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;


BEGIN
{
	use_ok( 'Perl::Critic::Policy::Perlsecret' );
}

diag( "Testing Perl::Critic::Policy::Perlsecret $Perl::Critic::Policy::Perlsecret::VERSION, Perl $], $^X" );
