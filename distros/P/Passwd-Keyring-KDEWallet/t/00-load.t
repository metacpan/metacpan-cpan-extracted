#!perl -T

use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Passwd::Keyring::KDEWallet' ) || print "Bail out!\n";
}

diag( "Testing Passwd::Keyring::KDEWallet $Passwd::Keyring::KDEWallet::VERSION, Perl $], $^X" );
diag( "Consider spawning  kwalletmanager  to observe test consequences" );
