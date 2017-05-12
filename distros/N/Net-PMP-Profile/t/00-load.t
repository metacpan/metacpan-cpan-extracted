use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::PMP::Profile' ) || print "Bail out!\n";
}

diag( "Testing Net::PMP::Profile $Net::PMP::Profile::VERSION, Perl $], $^X" );
