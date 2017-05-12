#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'POSIX::Open3' ) || print "Bail out!
";
}

diag( "Testing POSIX::Open3 $POSIX::Open3::VERSION, Perl $], $^X" );
