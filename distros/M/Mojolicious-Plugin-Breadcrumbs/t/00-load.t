#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 2;

BEGIN {
    use_ok('Mojo::Base');
    use_ok('Mojolicious::Plugin::Breadcrumbs') || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::Breadcrumbs $Mojolicious::Plugin::Breadcrumbs::VERSION, Perl $], $^X" );