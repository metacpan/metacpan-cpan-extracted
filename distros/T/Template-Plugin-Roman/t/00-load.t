#!perl -T
use v5.10;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Template::Plugin::Roman' ) || print "Bail out!\n";
}

diag( "Testing Template::Plugin::Roman $Template::Plugin::Roman::VERSION, Perl $], $^X" );
