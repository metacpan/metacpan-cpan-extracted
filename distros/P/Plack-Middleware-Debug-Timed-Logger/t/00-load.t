#!perl -T
use 5.16.0;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Plack::Middleware::Debug::Timed::Logger' ) || print "Bail out!\n";
}

diag( "Testing Plack::Middleware::Debug::Timed::Logger $Plack::Middleware::Debug::Timed::Logger::VERSION, Perl $], $^X" );
