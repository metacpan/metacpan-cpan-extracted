#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'SVN::Notify::Filter::AuthZMail' );
}

diag( "Testing SVN::Notify::Filter::AuthZMail $SVN::Notify::Filter::AuthZMail::VERSION, Perl $], $^X" );
