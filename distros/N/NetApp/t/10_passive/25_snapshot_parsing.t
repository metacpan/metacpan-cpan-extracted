#!/usr/bin/env perl -w

use strict;
use warnings;

use lib 'blib/lib';
use lib 't/lib';
use NetApp::Test;

use Test::More qw( no_plan );
use Test::Exception;
use Data::Dumper;

use NetApp::Filer;
use NetApp::Snapshot;

my $line = <<'__line__';
 28% (27%)    0% ( 0%)  May 07 15:06  sv_hourly.0
__line__

my $snapshot = NetApp::Snapshot->_parse_snap_list( $line );

ok( $snapshot->{used} == 27,
    'used value is correct: ' . $snapshot->{used} );
ok( $snapshot->{total} == 0,
    'total value is correct: ' . $snapshot->{total} );
ok( $snapshot->{date} eq 'May 07 15:06',
    'date value is correct: ' . $snapshot->{date} );
ok( $snapshot->{name} eq 'sv_hourly.0',
    'name value is correct: ' . $snapshot->{name} );

my @lines = split /\n+/, <<'__lines__';
nightly.1       Active File System   596           1d 12:39   16.255
hourly.1        hourly.0             3672          0d 07:59   459.223    
tempname        hourly.0             72                  2s   129600.000
__lines__

my $delta = NetApp::Snapshot::Delta->_parse_snap_delta( $lines[0] );

ok( $delta->{from} eq 'nightly.1',
    '1st from value is correct: ' . $delta->{from} );
ok( $delta->{to} eq 'active',
    '1st to value is correct: ' . $delta->{to} );
ok( $delta->{changed} == 596,
    '1st changed value is correct: ' . $delta->{changed} );
ok( $delta->{time} eq '1d 12:39',
    '1st time value is correct: ' . $delta->{time} );
ok( $delta->{rate} eq '16.255',
    '1st rate value is correct: ' . $delta->{rate} );

$delta = NetApp::Snapshot::Delta->_parse_snap_delta( $lines[1] );

ok( $delta->{from} eq 'hourly.1',
    '2nd from value is correct: ' . $delta->{from} );
ok( $delta->{to} eq 'hourly.0',
    '2nd to value is correct: ' . $delta->{to} );
ok( $delta->{changed} == 3672,
    '2nd changed value is correct: ' . $delta->{changed} );
ok( $delta->{time} eq '0d 07:59',
    '2nd time value is correct: ' . $delta->{time} );
ok( $delta->{rate} eq '459.223',
    '2nd rate value is correct: ' . $delta->{rate} );

$delta = NetApp::Snapshot::Delta->_parse_snap_delta( $lines[2] );

ok( $delta->{from} eq 'tempname',
    '2nd from value is correct: ' . $delta->{from} );
ok( $delta->{to} eq 'hourly.0',
    '2nd to value is correct: ' . $delta->{to} );
ok( $delta->{changed} == 72,
    '2nd changed value is correct: ' . $delta->{changed} );
ok( $delta->{time} eq '2s',
    '2nd time value is correct: ' . $delta->{time} );
ok( $delta->{rate} eq '129600.000',
    '2nd rate value is correct: ' . $delta->{rate} );

@lines = split /\n+/, <<'__lines__';
Volume one: 0 0 0
Volume two: 0 2 6@8,12,16,20
__lines__

my $schedule = NetApp::Snapshot::Schedule->_parse_snap_sched( $lines[0] );

ok( $schedule->{weekly} == 0,
    '1st weekly value is correct: ' . $schedule->{weekly} );
ok( $schedule->{daily} == 0,
    '1st daily value is correct: ' . $schedule->{daily} );
ok( $schedule->{hourly} == 0,
    '1st hourly value is correct: ' . $schedule->{hourly} );
ok( ref $schedule->{hourlist} eq 'ARRAY',
    '1st hourlist is an array ref' );
ok( scalar @{ $schedule->{hourlist} } == 0,
    '1st hourlist is empty' );

$schedule = NetApp::Snapshot::Schedule->_parse_snap_sched( $lines[1] );

ok( $schedule->{weekly} == 0,
    '2nd weekly value is correct: ' . $schedule->{weekly} );
ok( $schedule->{daily} == 2,
    '2nd daily value is correct: ' . $schedule->{daily} );
ok( $schedule->{hourly} == 6,
    '2nd hourly value is correct: ' . $schedule->{hourly} );
ok( ref $schedule->{hourlist} eq 'ARRAY',
    '2nd hourlist is an array ref' );
ok( scalar @{ $schedule->{hourlist} } == 4,
    '2nd hourlist has 4 elements' );
ok( $schedule->{hourlist}->[0] == 8 &&
        $schedule->{hourlist}->[1] == 12 &&
            $schedule->{hourlist}->[2] == 16 &&
                $schedule->{hourlist}->[3] == 20,
    '2nd hourlist has the correct values: ' .
        join( ',', @{ $schedule->{hourlist} } ) );

