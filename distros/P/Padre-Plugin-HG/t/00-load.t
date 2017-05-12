#!perl 

use Test::More tests => 1;

BEGIN {
    use_ok( 'Padre::Plugin::HG' );
}

diag( "Testing Padre::Plugin::HG $Padre::Plugin::HG::VERSION, Perl $], $^X" );
