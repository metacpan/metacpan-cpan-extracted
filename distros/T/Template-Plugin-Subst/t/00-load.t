#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Template::Plugin::Subst' );
}

diag( "Testing Template::Plugin::Subst $Template::Plugin::Subst::VERSION, Perl $], $^X" );
