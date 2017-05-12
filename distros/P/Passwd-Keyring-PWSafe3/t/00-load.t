#!perl -T

use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Passwd::Keyring::PWSafe3' ) || print "Bail out!\n";
}

diag( "Testing Passwd::Keyring::PWSafe3 $Passwd::Keyring::PWSafe3::VERSION, Crypt::PWSafe3 $Crypt::PWSafe3::VERSION, Perl $], $^X" );
