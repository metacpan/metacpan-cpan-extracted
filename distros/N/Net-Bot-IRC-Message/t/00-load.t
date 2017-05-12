#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::Bot::IRC::Message' );
}

diag( "Testing Net::Bot::IRC::Message $Net::Bot::IRC::Message::VERSION, Perl $], $^X" );
