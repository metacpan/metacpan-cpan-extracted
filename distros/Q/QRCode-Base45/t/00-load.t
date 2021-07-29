#!perl
use 5.10.0;
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'QRCode::Base45' ) || print "Bail out!\n";
}

diag( "Testing QRCode::Base45 $QRCode::Base45::VERSION, Perl $], $^X" );
