#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::XML::LX' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::XML::LX $Mojolicious::Plugin::XML::LX::VERSION, Perl $], $^X" );
