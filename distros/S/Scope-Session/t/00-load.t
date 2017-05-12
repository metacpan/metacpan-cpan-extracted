#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Scope::Session' ) || print "Bail out!
";
}

diag( "Testing Scope::Session $Scope::Session::VERSION, Perl $], $^X" );
