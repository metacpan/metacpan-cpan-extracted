#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::Command::Simple' ) || print "Bail out!
";
}

diag( "Testing Test::Command::Simple $Test::Command::Simple::VERSION, Perl $], $^X" );
