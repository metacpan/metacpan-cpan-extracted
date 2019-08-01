#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Progressive::Web::Application' ) || print "Bail out!\n";
}

diag( "Testing Progressive::Web::Application $Progressive::Web::Application::VERSION, Perl $], $^X" );
