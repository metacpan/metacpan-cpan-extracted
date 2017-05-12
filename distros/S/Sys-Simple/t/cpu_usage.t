#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

my $module = 'Sys::Simple::CPU::Linux';

require_ok( $module );

can_ok( $module, "cpu_usage");

like ( Sys::Simple::CPU::Linux::cpu_usage(), qr/[\d|\.]+/, "returns cpu usage\n");

like ( Sys::Simple::CPU::Linux::cpu_usage( 10 ), qr/[\d|\.]+/, "returns cpu usage with bigger interval time\n");

done_testing;
