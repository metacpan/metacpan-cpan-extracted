#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::AssetPack::Che' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::AssetPack::Che $Mojolicious::Plugin::AssetPack::Che::VERSION, Perl $], $^X" );
