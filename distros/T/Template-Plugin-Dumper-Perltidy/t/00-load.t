#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Template::Plugin::Dumper::Perltidy' );
}

diag( "Testing Template::Plugin::Dumper::Perltidy $Template::Plugin::Dumper::Perltidy::VERSION, Perl $], $^X" );
