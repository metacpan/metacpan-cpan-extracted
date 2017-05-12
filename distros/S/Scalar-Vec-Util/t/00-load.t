#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
 use_ok( 'Scalar::Vec::Util' );
}

diag( "Testing Scalar::Vec::Util $Scalar::Vec::Util::VERSION, Perl $], $^X" );
