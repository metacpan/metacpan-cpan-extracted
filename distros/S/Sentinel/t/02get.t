#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Sentinel;

my $value = sentinel get => sub { return "Hello, world"; };
is( $value, "Hello, world", 'sentinel get' );

my $getcount = 0;
my $vref = \sentinel get => sub { $getcount++; return "Another value"; };

is( $getcount, 0, '$getcount 0 before get' );

is( $$vref, "Another value", 'dereference vref yields value' );

is( $getcount, 1, '$getcount 1 after get' );

done_testing;
