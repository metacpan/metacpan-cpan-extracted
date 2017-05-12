#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'POE::Component::DirWatch::WithCaller' ) || print "Bail out!\n";
}

diag( "Testing POE::Component::DirWatch::WithCaller $POE::Component::DirWatch::WithCaller::VERSION, Perl $], $^X" );
