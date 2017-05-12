#!/usr/bin/env perl -w

use strict;
use warnings;

use lib 'blib/lib';
use lib 't/lib';
use NetApp::Test;

BEGIN {
    if ( not @NetApp::Test::filer_args ) {
        print "1..0 # Skipped: No test filers defined\n";
        exit 0;
    }
}

use Test::More qw( no_plan );
use Test::Exception;
use Data::Dumper;

use NetApp::Filer;
use NetApp::Aggregate;
use NetApp::Volume;
use NetApp::Snapmirror;

my @volume_names	= ();

foreach my $filer_args ( @NetApp::Test::filer_args ) {

    ok( ref $filer_args eq 'HASH',
        'filer_args entry is a HASH ref' );

    my $filer		= NetApp::Filer->new( $filer_args );
    isa_ok( $filer, 'NetApp::Filer' );

    print "# Running tests on filer " . $filer->get_hostname . "\n";

    my @snapmirrors	= $filer->get_snapmirrors;

    @volume_names	= ();

    foreach my $snapmirror ( @snapmirrors ) {
        test_snapmirror(
            snapmirror		=> $snapmirror,
            volume_names 	=> 1,
        );
    }

    foreach my $volume_name ( @volume_names ) {

        my $volume		= $filer->get_volume( $volume_name );
        isa_ok( $volume,	'NetApp::Volume' );

        my @volume_snapmirrors	= $volume->get_snapmirrors;
        ok( @volume_snapmirrors,'volume->get_snapmirrors returns list' );

        foreach my $volume_snapmirror ( @volume_snapmirrors ) {
            test_snapmirror(
                snapmirror	=> $volume_snapmirror,
            );
        }

    }

}

sub test_snapmirror {

    my (%args)		= @_;

    my $snapmirror	= $args{snapmirror};
    isa_ok( $snapmirror,	'NetApp::Snapmirror' );

    my $hostname	= $snapmirror->get_filer->get_hostname;

    if ( my $source	= $snapmirror->get_source ) {

        isa_ok( $source,	'NetApp::Snapmirror::Source' );

        my $source_hostname	= $source->get_hostname;
        ok( $source_hostname,
            "source->get_hostname: $source_hostname" );
        my $source_volume	= $source->get_volume;
        ok( $source_volume,
            "source->get_volume: $source_volume" );

        if ( $args{volume_names} &&
                 same_hostname( $hostname, $source_hostname ) ) {
            push @volume_names, $source_volume;
        }

    }

    my $destination	= $snapmirror->get_destination;
    isa_ok( $destination, 'NetApp::Snapmirror::Destination' );

    my $dest_hostname	= $destination->get_hostname;
    ok( $dest_hostname,
        "destination->get_hostname: $dest_hostname" );
    my $dest_volume	= $destination->get_volume;
    ok( $dest_volume,
        "destination->get_volume: $dest_volume" );

    if ( $args{volume_names} &&
             same_hostname( $hostname, $dest_hostname ) ) {
        push @volume_names, $dest_volume;
    }

    my @keys = qw( status progress state lag
                   mirror_timestamp base_snapshot
                   current_transfer_type current_transfer_error
                   contents
                   last_transfer_type last_transfer_size
                   last_transfer_duration last_transfer_from );

    foreach my $key ( @keys ) {
        my $method	= "get_$key";
        my $value	= $snapmirror->$method;
        ok( defined $value,	"snapmirror->$method: '$value'" );
    }

}

#
# Crude comparison of hostnames.  If both are FQDNs, they must be an
# exact match, otherwise, just compare the base hostnames.
#
sub same_hostname {

    my ($first,$second) = @_;

    if ( $first =~ /\./ && $second =~ /\./ ) {
        return $first eq $second;
    } else {
        ($first)	= split( /\./, $first );
        ($second)	= split( /\./, $second );
        return $first eq $second;
    }

}

