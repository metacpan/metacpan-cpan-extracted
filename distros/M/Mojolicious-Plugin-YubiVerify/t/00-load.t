#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::YubiVerify' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::YubiVerify $Mojolicious::Plugin::YubiVerify::VERSION, Perl $], $^X" );
