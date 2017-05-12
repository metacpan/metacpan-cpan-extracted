use Test::More tests => 3;

BEGIN {
use_ok( 'SQLite::Work' );
use_ok( 'SQLite::Work::CGI' );
use_ok( 'SQLite::Work::Mail' );
}

diag( "Testing SQLite::Work ${SQLite::Work::VERSION}" );
