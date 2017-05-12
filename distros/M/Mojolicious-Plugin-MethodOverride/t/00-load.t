#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::MethodOverride' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::MethodOverride $Mojolicious::Plugin::MethodOverride::VERSION, Perl $], $^X" );
