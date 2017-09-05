#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Plack::Middleware::Debug::Template' ) || print "Bail out!\n";
}

diag( "Testing Plack::Middleware::Debug::Template $Plack::Middleware::Debug::Template::VERSION, Perl $], $^X" );
