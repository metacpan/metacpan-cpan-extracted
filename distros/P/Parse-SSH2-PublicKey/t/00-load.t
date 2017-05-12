#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Parse::SSH2::PublicKey' ) || print "Bail out!\n";
}

diag( "Testing Parse::SSH2::PublicKey $Parse::SSH2::PublicKey::VERSION, Perl $], $^X" );
