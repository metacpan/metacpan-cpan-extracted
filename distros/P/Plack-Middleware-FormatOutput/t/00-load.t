#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Plack::Middleware::FormatOutput' ) || print "Bail out!\n";
}

diag( "Testing Plack::Middleware::FormatOutput $Plack::Middleware::FormatOutput::VERSION, Perl $], $^X" );
