#!perl -T

use Test::More tests => 1;

BEGIN {
        use_ok( 'Script::Resume' );
}

diag( "Testing Script::Resume $Script::Resume::VERSION, Perl $], $^X" );
