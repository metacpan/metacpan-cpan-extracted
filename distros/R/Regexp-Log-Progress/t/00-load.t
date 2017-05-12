#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Regexp::Log::Progress::Database' ) || print "Bail out!\n";
    use_ok( 'Regexp::Log::Progress' )           || print "Bail out!\n";
}

diag( "Testing Regexp::Log::Progress $Regexp::Log::Progress::VERSION, Perl $], $^X" );
