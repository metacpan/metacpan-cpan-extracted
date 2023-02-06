#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Terse::Plugin::CHI' ) || print "Bail out!\n";
}

diag( "Testing Terse::Plugin::CHI $Terse::Plugin::CHI::VERSION, Perl $], $^X" );
