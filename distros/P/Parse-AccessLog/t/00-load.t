#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Parse::AccessLog' ) || print "Bail out!\n";
}

diag( "Testing Parse::AccessLog $Parse::AccessLog::VERSION, Perl $], $^X" );
