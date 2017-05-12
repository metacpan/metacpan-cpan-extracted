#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MojoX::Session::Store::Redis' ) || print "Bail out!
";
}

diag( "Testing MojoX::Session::Store::Redis $MojoX::Session::Store::Redis::VERSION, Perl $], $^X" );
