#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0 0.000149;

use Sublike::Extended;
use Signature::Attribute::Alias;

use experimental 'signatures';

like( eval( 'extended sub f ( @x :Alias ) { } 1' ) ? undef : $@,
   qr/^Can only apply the :Alias attribute to scalar parameters at /,
   ':Alias on non-scalars is not permitted' );

like( eval( 'extended sub f ( $x :Alias = 1234 ) { } 1' ) ? undef : $@,
   qr/^Cannot apply the :Alias attribute to a parameter with a defaulting expression at /,
   ':Alias on param with defaulting expression is not permitted' );

like( eval( 'extended sub f ( :$x :Alias ) { } 1' ) ? undef : $@,
   qr/^Cannot apply the :Alias attribute to a named parameter at /,
   ':Alias on named param is not permitted' );

done_testing;
