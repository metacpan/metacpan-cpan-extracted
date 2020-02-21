#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::Minion::Overview' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::Minion::Overview $Mojolicious::Plugin::Minion::Overview::VERSION, Perl $], $^X" );
