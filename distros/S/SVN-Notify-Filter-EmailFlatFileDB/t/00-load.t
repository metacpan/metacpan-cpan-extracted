#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'SVN::Notify::Filter::EmailFlatFileDB' );
}

diag( "Testing SVN::Notify::Filter::EmailFlatFileDB $SVN::Notify::Filter::EmailFlatFileDB::VERSION, Perl $], $^X" );
