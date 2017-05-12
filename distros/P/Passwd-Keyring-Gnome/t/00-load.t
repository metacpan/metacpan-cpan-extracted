#!perl -T

use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Passwd::Keyring::Gnome' ) || print "Bail out!\n";
}

diag( "Testing Passwd::Keyring::Gnome $Passwd::Keyring::Gnome::VERSION, Perl $], $^X" );
diag( "Consider spawning  seahorse  and observing password changes caused by tests" );
