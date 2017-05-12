#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

my $module = 'Sys::Simple';

my @methods = qw/
    cpu_usage
/;

require_ok( $module );

use_ok( $module, @methods );

can_ok( $module, "cpu_usage");

like ( cpu_usage(), qr/[\d|\.]+/, "returns cpu usage\n");

like ( cpu_usage( 10 ), qr/[\d|\.]+/, "returns cpu usage with bigger interval time\n");

 done_testing;
