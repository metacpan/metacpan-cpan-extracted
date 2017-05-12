#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Module::Build::JSAN::Installable' );
}

diag( "Testing Module::Build::JSAN::Installable $Module::Build::JSAN::Installable::VERSION, Perl $], $^X" );
