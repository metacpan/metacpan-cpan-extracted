#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Mojolicious::Plugin::KossyValidator' );
}

diag( "Testing Mojolicious::Plugin::KossyValidator $Mojolicious::Plugin::KossyValidator::VERSION, Perl $], $^X" );
