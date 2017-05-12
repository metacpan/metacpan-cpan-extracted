#!/usr/bin/env perl

use Test::More tests => 8;

use warnings;
use strict;

use Proc::LoadMonitor;

my $lmon = Proc::LoadMonitor->new;

for ( 1 .. 10 ) {
    $lmon->busy;
    $lmon->idle;
}

for ( 1 .. 5 ) {
    $lmon->idle;
}

$lmon->busy;
is( $lmon->state, 'busy', 'busy' );

sleep 2;

$lmon->idle;
is( $lmon->state, 'idle', 'idle' );

my $report = $lmon->report;

is( $report->{jobs},  11, 'jobs' );
is( $report->{loops}, 16, 'loops' );

ok( $report->{total} > 0, 'total > 0' );

ok( $report->{load_15} > 0,                  'load_15 > 0' );
ok( $report->{load_10} > $report->{load_15}, 'load_10 > load_15' );
ok( $report->{load_05} > $report->{load_10}, 'load_05 > load_10' );
