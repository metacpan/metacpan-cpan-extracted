#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Plack::Session::Store::Redis' ) || print "Bail out!
";
}

diag( "Testing Plack::Session::Store::Redis $Plack::Session::Store::Redis::VERSION, Perl $], $^X" );
