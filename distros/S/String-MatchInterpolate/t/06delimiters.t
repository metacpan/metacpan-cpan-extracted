#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;
use Test::Exception;

use String::MatchInterpolate;

my $smi = String::MatchInterpolate->new(
   'prefix[[VAR/\w+/]]suffix',
   delimiters => [qr/\[\[/, qr/\]\]/],
);

ok( defined $smi, 'defined $smi with delimiters' );

is_deeply( [$smi->vars], [qw( VAR )], '$smi->vars' );

is_deeply( scalar $smi->match( "prefixmiddlesuffix" ), { VAR => "middle" }, 'matched correct keys' );

is( $smi->interpolate( { VAR => "value" } ), "prefixvaluesuffix", 'interpolates correct string' );
