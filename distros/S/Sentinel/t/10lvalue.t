#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use Sentinel;

my $value;
sentinel( set => sub { $value = shift } ) = "Value";

is( $value, "Value", 'sentinel() as lvalue sub' );
