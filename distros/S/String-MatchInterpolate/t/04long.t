#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;

use String::MatchInterpolate;

my $smi = String::MatchInterpolate->new( join( " ", map { "$_=\${$_/./}" } 'A' .. 'Z' ) );

ok( defined $smi, 'defined $smi long' );

is_deeply( [ $smi->vars ], [ 'A' .. 'Z' ], '$smi->vars' );

my $str = join( " ", map { "$_=" . lc $_ } 'A' .. 'Z' );

my $vars = $smi->match( $str );
is_deeply( $vars, { map { $_ => lc $_ } 'A' .. 'Z' }, 'match' );

is( $smi->interpolate( $vars ), $str, 'interpolate' );
