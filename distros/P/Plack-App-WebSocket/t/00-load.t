use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Plack::App::WebSocket' ) || print "Bail out!\n";
}

diag( "Testing Plack::App::WebSocket $Plack::App::WebSocket::VERSION, Perl $], $^X" );
