#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::WWWSession' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::WWWSession $Mojolicious::Plugin::WWWSession::VERSION, Perl $], $^X" );
