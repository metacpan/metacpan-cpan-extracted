use strict;
use warnings;

use Test::More tests => 1;                      # last test to print


BEGIN {
    use_ok( 'Net::Gandi' ) || print "Bail out";
}

diag( "Testing Net::Gandi $Net::Gandi::VERSION, Perl $], $^X" );
