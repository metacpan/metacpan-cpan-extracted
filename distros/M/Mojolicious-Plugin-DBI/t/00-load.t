#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::DBI' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::DBI $Mojolicious::Plugin::DBI::VERSION, Perl $], $^X" );
