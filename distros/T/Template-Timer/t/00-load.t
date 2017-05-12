#!perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok( 'Template::Timer' );
}

diag( "Testing Template::Timer $Template::Timer::VERSION" );
