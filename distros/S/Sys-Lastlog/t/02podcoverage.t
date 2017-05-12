#!/usr/bin/perl

use Test::More;
eval "use Test::Pod::Coverage tests => 1";
plan skip_all => "Test::Pod::Coverage required for testing POD Coverage" if $@;
pod_coverage_ok( "Sys::Lastlog", {also_private => [ qr/constant/]},
                  "Sys::Lastlog is covered" );
 

