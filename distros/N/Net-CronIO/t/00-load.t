#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::CronIO' ) || print "Bail out!\n";
}

diag( "Testing Net::CronIO $Net::CronIO::VERSION, Perl $], $^X" );
