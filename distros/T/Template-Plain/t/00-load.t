#!perl -T

use Test::More tests => 1;
BEGIN {
    use_ok( 'Template::Plain' ) || BAIL_OUT("Failed to load module.");
}

diag( "Testing Template::Plain $Template::Plain::VERSION, Perl $], $^X" );
