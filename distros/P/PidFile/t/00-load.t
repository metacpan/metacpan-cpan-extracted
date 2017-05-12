#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'PidFile' ) || print "Bail out!\n";
}

diag( "Testing PidFile $PidFile::VERSION, Perl $], $^X" );
