#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Che' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Che $Mojolicious::Che::VERSION, Perl $], $^X" );
