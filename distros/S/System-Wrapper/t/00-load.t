#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'System::Wrapper' ) || print "Bail out!
";
}

diag( "Testing System::Wrapper $System::Wrapper::VERSION, Perl $], $^X" );
