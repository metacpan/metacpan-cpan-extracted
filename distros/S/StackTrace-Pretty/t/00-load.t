#!perl -T
use 5.006;
use strict;
use warnings;

use lib qw(lib);

use Test::More tests => 1;

BEGIN {
    use_ok( 'StackTrace::Pretty' ) || print "Bail out!\n";
}

diag( "Testing StackTrace::Pretty $StackTrace::Pretty::VERSION, Perl $], $^X" );
