#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::UniqueTagHelpers' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::UniqueTagHelpers $Mojolicious::Plugin::UniqueTagHelpers::VERSION, Perl $], $^X" );
