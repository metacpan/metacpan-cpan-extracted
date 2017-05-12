#!/usr/bin/perl

use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;

plan tests => 1;
pod_coverage_ok( "Schedule::Cron",{trustme => [qr/^REAPER$/, qr/^bug$/, qr/^report_exectime_bug/]}, "Schedule::Cron is covered" );
