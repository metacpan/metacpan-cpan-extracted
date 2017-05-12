#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Passwd::Keyring::OSXKeychain' ) || print "Bail out!\n";
}

diag( "Testing Passwd::Keyring::OSXKeychain $Passwd::Keyring::OSXKeychain::VERSION, Perl $], $^X" );
#diag( "Consider spawning  GUI  and checking whether all passwords are properly wiped after tests" );
