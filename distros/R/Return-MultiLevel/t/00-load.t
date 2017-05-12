#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Return::MultiLevel' );
}

diag( "Testing Return::MultiLevel $Return::MultiLevel::VERSION ($Return::MultiLevel::_backend), Perl $], $^X" );
