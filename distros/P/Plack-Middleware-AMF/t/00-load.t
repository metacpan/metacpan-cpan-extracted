#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Plack::Middleware::AMF' ) || print "Bail out!
";
}

diag( "Testing Plack::Middleware::AMF $Plack::Middleware::AMF::VERSION, Perl $], $^X" );
