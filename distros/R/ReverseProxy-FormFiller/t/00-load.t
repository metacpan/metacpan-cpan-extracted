#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'ReverseProxy::FormFiller' ) || print "Bail out!
";
}

diag( "Testing ReverseProxy::FormFiller $ReverseProxy::FormFiller::VERSION, Perl $], $^X" );
