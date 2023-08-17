#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Sentinel;

my $value;
sentinel( set => sub { $value = shift } ) = "Value";

is( $value, "Value", 'sentinel() as lvalue sub' );

done_testing;
