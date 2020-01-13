#!perl -T
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Template::Plugin::Lingua::EN::Inflexion' ) || print "Bail out!\n";
}

diag( "Testing Template::Plugin::Lingua::EN::Inflexion $Template::Plugin::Lingua::EN::Inflexion::VERSION, Perl $], $^X" );
