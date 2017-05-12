#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Script::Daemonizer' ) || print "Bail out!\n";
}

diag( "Testing Script::Daemonizer $Script::Daemonizer::VERSION, Perl $], $^X" );
