#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Passwd::Keyring::Memory' ) || print "Bail out!\n";
}

diag( "Testing Passwd::Keyring::Memory $Passwd::Keyring::Memory::VERSION, Perl $], $^X" );
