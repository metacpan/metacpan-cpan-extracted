#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Refcount;

use Sentinel;

my $value = sentinel value => "Hello, world";
is( $value, "Hello, world", 'sentinel value' );

my $vref = \sentinel value => "Another value";
is( ref $vref, "SCALAR", '\sentinel yields SCALAR ref' );
is( $$vref, "Another value", 'deference vref' );

my $arr = [ 1, 2, 3 ];
is_oneref( $arr, '$arr has refcount 1 before \sentinel' );

$vref = \sentinel value => $arr;
is_refcount( $arr, 2, '$arr has refcount 2 after \sentinel' );

undef $vref;
is_oneref( $arr, '$arr has refcount 1 after undef $vref' );
