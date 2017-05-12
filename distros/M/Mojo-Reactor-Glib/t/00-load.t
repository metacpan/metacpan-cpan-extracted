#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib 'lib';

plan tests => 1;

BEGIN {
    use_ok( 'Mojo::Reactor::Glib' ) || print "Bail out!\n";
}

diag( "Testing Mojo::Reactor::Glib $Mojo::Reactor::Glib::VERSION, Perl $], $^X" );
