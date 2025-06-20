#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Reactive::Mojo::Plugin' ) || print "Bail out!\n";
}

diag( "Testing Reactive::Mojo::Plugin $Reactive::Mojo::Plugin::VERSION, Perl $], $^X" );
