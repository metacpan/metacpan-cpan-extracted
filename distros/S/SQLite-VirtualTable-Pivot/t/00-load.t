#!perl -T

use Test::More tests => 1;

BEGIN {
    $ENV{SQLITE_CURRENT_DB} = "/tmp/sqlite-vtable-test";
    use_ok( 'SQLite::VirtualTable::Pivot' );
}

diag( "Testing SQLite::VirtualTable::Pivot $SQLite::VirtualTable::Pivot::VERSION, Perl $], $^X" );
