#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Path::Class::File::Lockable' );
}

diag( "Testing Path::Class::File::Lockable $Path::Class::File::Lockable::VERSION, Perl $], $^X" );
