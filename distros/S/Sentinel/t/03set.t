#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;

use Sentinel;

my $value = sentinel value => "Hello, world", set => sub { };
is( $value, "Hello, world", 'sentinel value with set' );

my $setcount = 0;
my $vref = \sentinel value => "Current", set => sub { $setcount++; $value = shift };

is( $setcount, 0, '$setcount 0 before set' );

is( $$vref, "Current", 'dereference vref yields Current before set' );
$$vref = "Changed";

is( $setcount, 1, '$setcount 1 after set' );
is( $value, "Changed", '$value is Changed after set' );
is( $$vref, "Changed", 'dereference vref yields Changed after set' );

my $othervar = 1;
$vref = \sentinel get => sub { $othervar }, set => sub { $othervar = shift };

is( $$vref, 1, 'New vref 1 before incr' );
$$vref++;
is( $othervar, 2, '$othervar 2 after incr' );
is( $$vref,    2, 'dereference vref 2 after incr' );
