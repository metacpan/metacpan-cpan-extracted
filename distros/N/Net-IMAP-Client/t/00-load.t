#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::IMAP::Client' );
}

diag( "Testing Net::IMAP::Client $Net::IMAP::Client::VERSION, Perl $], $^X" );
