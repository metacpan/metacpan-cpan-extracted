#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MojoX::Encode::Gzip' );
}

diag( "Testing MojoX::Encode::Gzip $MojoX::Encode::Gzip::VERSION, Perl $], $^X" );
