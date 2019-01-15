#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Sentinel;

my $value;
sentinel( set => sub { $value = shift } ) = "Value";

is( $value, "Value", 'sentinel() as lvalue sub' );

done_testing;
