#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::Comcast::Customer' ) || print "Bail out!
";
}

diag( "Testing Net::Comcast::Customer $Net::Comcast::Customer::VERSION, Perl $], $^X" );
