use Test::More tests => 1;

BEGIN {
use_ok( 'Net::SMTP::Pipelining' );
}

diag( "Testing Net::SMTP::Pipelining $Net::SMTP::Pipelining::VERSION" );
