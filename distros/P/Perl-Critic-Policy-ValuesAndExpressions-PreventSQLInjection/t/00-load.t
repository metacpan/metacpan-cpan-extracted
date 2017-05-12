#!perl -T

use strict;
use warnings;


use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;


BEGIN
{
	use_ok( 'Perl::Critic::Policy::ValuesAndExpressions::PreventSQLInjection' );
}

diag( "Testing Perl::Critic::Policy::ValuesAndExpressions::PreventSQLInjection $Perl::Critic::Policy::ValuesAndExpressions::PreventSQLInjection::VERSION, Perl $], $^X" );
