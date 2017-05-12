#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Nagios::Scrape' ) || print "Bail out!
";
}

diag( "Testing Nagios::Scrape $Nagios::Scrape::VERSION, Perl $], $^X" );
