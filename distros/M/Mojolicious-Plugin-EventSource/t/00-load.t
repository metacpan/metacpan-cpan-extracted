#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::EventSource' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::EventSource $Mojolicious::Plugin::EventSource::VERSION, Perl $], $^X" );
