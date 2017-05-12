#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::Renderer::WithoutCache' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::Renderer::WithoutCache $Mojolicious::Plugin::Renderer::WithoutCache::VERSION, Perl $], $^X" );
