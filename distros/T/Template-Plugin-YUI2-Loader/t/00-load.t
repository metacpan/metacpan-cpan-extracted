#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Template::Plugin::YUI2::Loader' );
}

diag( "Testing Template::Plugin::YUI2::Loader $Template::Plugin::YUI2::Loader::VERSION, Perl $], $^X" );
