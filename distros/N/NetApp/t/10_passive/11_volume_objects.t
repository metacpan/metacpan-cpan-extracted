#!/usr/bin/env perl -w

use strict;
use warnings;

use lib 'blib/lib';
use lib 't/lib';
use NetApp::Test;

BEGIN {
    if ( not @NetApp::Test::filer_args ) {
        print "1..0 # Skip: No test filers defined\n";
        exit 0;
    }
}

use Test::More qw( no_plan );
use Test::Exception;
use Data::Dumper;

use NetApp::Filer;
use NetApp::Aggregate;
use NetApp::Volume;

foreach my $filer_args ( @NetApp::Test::filer_args ) {

    ok( ref $filer_args eq 'HASH',
        'filer_args entry is a HASH ref' );

    my $filer		= NetApp::Filer->new( $filer_args );
    isa_ok( $filer, 'NetApp::Filer' );

    print "# Running tests on filer " . $filer->get_hostname . "\n";

    my @volume_names	= $filer->get_volume_names;
    ok( @volume_names,	"filer->get_volume_names" );

    my @volumes		= $filer->get_volumes;
    ok( @volumes,	"filer->get_volumes" );

    foreach my $volume ( @volumes ) {

        isa_ok( $volume, 		'NetApp::Volume' );
        isa_ok( $volume->get_filer, 	'NetApp::Filer' );
        isa_ok( $volume->get_plex,	'NetApp::Aggregate::Plex' );

        foreach my $raidgroup ( $volume->get_plex->get_raidgroups ) {
            isa_ok( $raidgroup,		'NetApp::Aggregate::RAIDGroup' );
        }

        if ( $volume->get_status( 'flex' ) ) {

            ok( $volume->get_size,	'volume->get_size' );

            my $aggregate	= $volume->get_aggregate;
            isa_ok( $aggregate,		'NetApp::Aggregate' );

            my @aggr_volumes	= $aggregate->get_volumes;
            ok( @aggr_volumes,	"aggregate->get_volumes" );

            foreach my $aggr_volume ( @aggr_volumes ) {
                isa_ok( $aggr_volume,	'NetApp::Volume' );
            }

            my @volume_names	= $aggregate->get_volume_names;
            ok( @volume_names,	"aggregate->volume_names" );

            foreach my $volume_name ( @volume_names ) {
                isa_ok( $aggregate->get_volume( $volume_name ),
                        "NetApp::Volume" );
            }

        }

        if ( $volume->get_clone_names ) {
            foreach my $clone ( $volume->get_clones ) {
                isa_ok( $clone,		'NetApp::Volume' );
            }
        }

        if ( $volume->is_clone ) {
            ok( $volume->get_parent_name,	'volume->get_parent_name' );
            isa_ok( $volume->get_parent,	'NetApp::Volume' );
        }

        if ( $volume->get_status( 'flexcache' ) ) {
            isa_ok( $volume->get_source,	'NetApp::Volume::Source' );
        }

        my @states		= $volume->get_states;
        ok( @states,	"volume->get_states" );

        foreach my $state ( @states ) {
            ok( $volume->get_state( $state ),
                "volume->get_state($state)" );
        }

        ok( ! $volume->get_state( 'bogus' ),
            'volume->get_state(bogus) returns false' );

        my @statuses	= $volume->get_statuses;
        ok( @statuses,	"volume->get_statuses" );

        foreach my $status ( @statuses ) {
            ok( $volume->get_status( $status ),
                "volume->get_status($status)" );
        }

        ok( ! $volume->get_status( 'bogus' ),
            'volume->get_status(bogus) returns false' );

        my @options		= $volume->get_options;
        ok( @options,	"volume->get_options" );

        foreach my $option ( @options ) {
            ok( defined $volume->get_option( $option ),
                "volume->get_option($option)" );
        }

        ok( ! defined $volume->get_option( 'bogus' ),
            'volume->get_option(bogus) returns undef' );

    }

}
