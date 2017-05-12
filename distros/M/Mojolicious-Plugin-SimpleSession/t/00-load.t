#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::SimpleSession' );
}

diag( "Testing Mojolicious::Plugin::SimpleSession $Mojolicious::Plugin::SimpleSession::VERSION, Perl $], $^X" );
