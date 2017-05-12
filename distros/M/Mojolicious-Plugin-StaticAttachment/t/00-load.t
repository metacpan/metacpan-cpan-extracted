#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::StaticAttachment' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::StaticAttachment $Mojolicious::Plugin::StaticAttachment::VERSION, Perl $], $^X" );
