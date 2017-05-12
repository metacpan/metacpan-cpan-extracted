#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Template::Plugin::ListCompare' );
}

diag( "Testing Template::Plugin::ListCompare $Template::Plugin::ListCompare::VERSION, Perl $], $^X" );
