#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Object::Recorder' );
}

diag( "Testing Object::Recorder $Object::Recorder::VERSION, Perl $], $^X" );
