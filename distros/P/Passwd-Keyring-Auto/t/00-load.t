#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Passwd::Keyring::Auto' ) || print "Bail out!
";
    use_ok( 'Passwd::Keyring::Auto', 'get_keyring' ) || print "Bail out!
";
}

diag( "Testing Passwd::Keyring::Auto $Passwd::Keyring::Auto::VERSION, Perl $], $^X" );
