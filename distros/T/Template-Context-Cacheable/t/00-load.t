#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Template::Context::Cacheable' );
}

diag( "Testing Template::Context::Cacheable $Template::Context::Cacheable::VERSION, Perl $], $^X" );
