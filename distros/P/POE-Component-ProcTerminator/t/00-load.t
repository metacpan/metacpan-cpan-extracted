#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'POE::Component::ProcTerminator' ) || print "Bail out!
";
}

diag( "Testing POE::Component::ProcTerminator $POE::Component::ProcTerminator::VERSION, Perl $], $^X" );
