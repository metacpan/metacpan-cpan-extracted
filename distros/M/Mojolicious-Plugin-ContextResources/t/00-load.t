#!perl -T
use 5.006;
use strict;
use warnings;
use lib qw(lib);
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::ContextResources' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::ContextResources $Mojolicious::Plugin::ContextResources::VERSION, Perl $], $^X" );
