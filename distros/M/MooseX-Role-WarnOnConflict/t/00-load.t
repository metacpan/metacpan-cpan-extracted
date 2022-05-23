#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MooseX::Role::WarnOnConflict' );
}

diag( "Testing MooseX::Role::WarnOnConflict $MooseX::Role::WarnOnConflict::VERSION, Perl $], $^X" );
