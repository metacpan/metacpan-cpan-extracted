#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::Helper::Vars' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::Helper::Vars $Mojolicious::Plugin::Helper::Vars::VERSION, Perl $], $^X" );
