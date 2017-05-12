#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::SMS::160By2' ) || print "Bail out!
";
}

diag( "Testing Net::SMS::160By2 $Net::SMS::160By2::VERSION, Perl $], $^X" );
