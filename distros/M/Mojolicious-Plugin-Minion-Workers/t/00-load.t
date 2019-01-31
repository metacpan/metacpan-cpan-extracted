#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::Minion::Workers' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::Minion::Workers $Mojolicious::Plugin::Minion::Workers::VERSION, Perl $], $^X" );
