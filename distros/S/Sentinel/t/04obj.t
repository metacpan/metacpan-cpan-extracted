#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;
use Test::Refcount;

use Scalar::Util qw( refaddr );

use Sentinel;

my $obj = [];

my @getargs;
sub value_get { @getargs = @_; return "Hello, world" }

my @setargs;
sub value_set { @setargs = @_; }

is_oneref( $obj, 'Object has refcount 1 before sentinel' );

my $vref = \sentinel obj => $obj, get => \&value_get, set => \&value_set;

is_refcount( $obj, 2, 'Object has refcount 2 after sentinel' );

is( $$vref, "Hello, world", 'sentinel value with obj' );
is( scalar @getargs, 1, 'get callback passed 1 argument' );
is( refaddr $getargs[0], refaddr $obj, 'get callback arg[0] is obj' );

$$vref = "New value";
is( scalar @setargs, 2, 'set callback passed 2 arguments' );
is( refaddr $setargs[0], refaddr $obj, 'set callback arg[0] is obj' );
is( $setargs[1], "New value", 'set callback arg[1] is New value' );

undef @getargs;
undef @setargs;
undef $vref;

is_oneref( $obj, 'Object has refcount 1 after undef $vref' );
