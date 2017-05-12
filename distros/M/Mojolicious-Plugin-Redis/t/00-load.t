#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Mojolicious::Plugin::Redis' );
}

diag( "Testing Mojolicious::Plugin::Redis $Mojolicious::Plugin::Redis::VERSION, Perl $], $^X" );
