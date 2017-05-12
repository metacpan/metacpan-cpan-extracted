#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Plack::Middleware::Scope::Session' ) || print "Bail out!
";
}

diag( "Testing Plack::Middleware::Scope::Session $Plack::Middleware::Scope::Session::VERSION, Perl $], $^X" );
