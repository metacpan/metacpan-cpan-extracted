#!perl 

use Test::More tests => 1;

BEGIN {
    use_ok( 'RRD::Editor' ) || print "Bail out!\n";
}

diag( "Testing RRD::Editor $RRD::Editor::VERSION, Perl $], $^X" );
