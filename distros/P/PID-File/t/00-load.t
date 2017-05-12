#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'PID::File' ) || print "Bail out!\n";
}

diag( "Testing PID::File $PID::File::VERSION, Perl $], $^X" );
