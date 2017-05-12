#!/usr/bin/perl

use Test::More;
eval "use Test::Pod::Coverage tests => 2";
plan skip_all => "Test::Pod::Coverage required for testing POD Coverage" if $@;
pod_coverage_ok( "Sys::Utmp", {also_private => [ qr/constant/]},
                  "Sys::Utmp is covered" );
pod_coverage_ok( "Sys::Utmp::Utent", {also_private => [ qr/^UT_/]},
                  "Sys::Utmp::Utent is covered (ignoring field constants)" );
 

