#!perl -T

use Test::More tests => 1;

BEGIN {
    use lib './';
    use_ok( 'Proc::Async' );
}

diag( "Testing Proc::Async $Proc::Async::VERSION, Perl $], $^X" );
