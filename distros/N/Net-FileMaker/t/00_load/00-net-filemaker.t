use strict;
use warnings;

use Test::More tests => 1;


BEGIN {
    use_ok( 'Net::FileMaker' ) || print "Bail out!";
}

diag( "Testing Net::FileMaker $Net::FileMaker::VERSION, Perl $], $^X" );
