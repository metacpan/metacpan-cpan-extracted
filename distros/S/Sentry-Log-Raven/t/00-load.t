#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Sentry::Log::Raven' ) || print "Bail out!\n";
}

diag( "Testing Sentry::Log::Raven $Sentry::Log::Raven::VERSION, Perl $], $^X" );
