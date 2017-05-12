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
use NetApp::Snapmirror;

my @lines = split /\n/, <<__lines__;
Source:                 source_hostname:source_volume
Destination:            destination_hostname:destination_volume
Status:                 Transferring
Progress:               0 KB
State:                  Source
Lag:                    00:01:37
Mirror Timestamp:       Wed Aug 13 12:58:01 EDT 2008
Base Snapshot:          base_snapshot_name
Current Transfer Type:  -
Current Transfer Error: -
Contents:               -
Last Transfer Type:     -
Last Transfer Size:     1248 KB
Last Transfer Duration: 00:00:44
Last Transfer From:     -
__lines__

my $snapmirror		= {};

foreach my $index ( 0 .. $#lines ) {
    $snapmirror = NetApp::Snapmirror->_parse_snapmirror_status(
        snapmirror	=> $snapmirror,
        line		=> $lines[$index],
    );
}

ok( ref $snapmirror->{source} eq 'HASH',
    'source is a HASH ref' );
ok( $snapmirror->{source}->{hostname} eq 'source_hostname',
    'source hostname is correct' );
ok( $snapmirror->{source}->{volume} eq 'source_volume',
    'source volume is correct' );

ok( ref $snapmirror->{destination} eq 'HASH',
    'destination is a HASH ref' );
ok( $snapmirror->{destination}->{hostname} eq 'destination_hostname',
    'destination hostname is correct' );
ok( $snapmirror->{destination}->{volume} eq 'destination_volume',
    'destination volume is correct' );

ok( $snapmirror->{status} eq 'Transferring',
    'status is correct' );
ok( $snapmirror->{progress} eq '0 KB',
    'progress is correct' );
ok( $snapmirror->{state} eq 'Source',
    'state is correct' );
ok( $snapmirror->{lag} eq '00:01:37',
    'lag is correct' );
ok( $snapmirror->{mirror_timestamp} eq 'Wed Aug 13 12:58:01 EDT 2008',
    'mirror_timestamp is correct' );
ok( $snapmirror->{base_snapshot} eq 'base_snapshot_name',
    'base_snapshot is correct' );
ok( $snapmirror->{last_transfer_size} eq '1248 KB',
    'last_transfer_size is correct' );
ok( $snapmirror->{last_transfer_duration} eq '00:00:44',
    'last_transfer_duration is correct' );

foreach my $key ( qw( current_transfer_type current_transfer_error
                      contents last_transfer_type last_transfer_from ) ) {
    ok( $snapmirror->{$key} eq '', "$key is correct" );
}
