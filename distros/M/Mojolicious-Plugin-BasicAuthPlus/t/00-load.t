#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::BasicAuthPlus' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::BasicAuthPlus $Mojolicious::Plugin::BasicAuthPlus::VERSION, Perl $], $^X" );
