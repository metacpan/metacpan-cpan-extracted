#!perl -T
use 5.006;
use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok( 'Oracle::ZFSSA::Client' ) || print "Bail out!\n";
}

diag( "Testing Oracle::ZFSSA::Client $Oracle::ZFSSA::Client::VERSION, Perl $], $^X" );
