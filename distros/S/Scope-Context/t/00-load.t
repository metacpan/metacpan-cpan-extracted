#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
 use_ok( 'Scope::Context' );
}

diag( "Testing Scope::Context $Scope::Context::VERSION, Perl $], $^X" );
