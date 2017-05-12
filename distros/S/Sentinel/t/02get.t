#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use Sentinel;

my $value = sentinel get => sub { return "Hello, world"; };
is( $value, "Hello, world", 'sentinel get' );

my $getcount = 0;
my $vref = \sentinel get => sub { $getcount++; return "Another value"; };

is( $getcount, 0, '$getcount 0 before get' );

is( $$vref, "Another value", 'dereference vref yields value' );

is( $getcount, 1, '$getcount 1 after get' );
