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

foreach my $filer_args ( @NetApp::Test::filer_args ) {

    ok( ref $filer_args eq 'HASH',
        'filer_args entry is a HASH ref' );

    my $filer	= NetApp::Filer->new( $filer_args );
    isa_ok( $filer, 'NetApp::Filer' );

    print "# Running tests on filer " . $filer->get_hostname . "\n";

    my @aggregate_names	= $filer->get_aggregate_names;
    ok( @aggregate_names,	"get_aggregate_names" );

    my @aggregates	= $filer->get_aggregates;
    ok( @aggregates,	"get_aggregates" );

    foreach my $aggregate ( @aggregates ) {

        isa_ok( $aggregate, 		'NetApp::Aggregate' );
        isa_ok( $aggregate->get_filer, 	'NetApp::Filer' );

        my $plex		= $aggregate->get_plex;
        isa_ok( $plex,		'NetApp::Aggregate::Plex' );

        foreach my $raidgroup ( $plex->get_raidgroups ) {
            isa_ok( $raidgroup,	'NetApp::Aggregate::RAIDGroup' );
        }

        my @states		= $aggregate->get_states;
        ok( @states,		'aggregate->get_states' );

        foreach my $state ( @states ) {
            ok( $aggregate->get_state( $state ),
                "aggregate->get_state($state)" );
        }

        ok( ! $aggregate->get_state( 'bogus' ),
            'aggregate->get_state(bogus) returns false' );

        my @statuses	= $aggregate->get_statuses;
        ok( @statuses,	'aggregate->get_statuses' );

        foreach my $status ( @statuses ) {
            ok( $aggregate->get_status( $status ),
                "aggregate->get_status($status)" );
        }

        ok( ! $aggregate->get_status( 'bogus' ),
            'aggregate->get_status(bogus) returns false' );

        my @options	= $aggregate->get_options;
        ok( @options,	'aggregate->get_options' );

        foreach my $option ( @options ) {
            ok( defined $aggregate->get_option( $option ),
                "aggregate->get_option($option)" );
        }

        ok( ! defined $aggregate->get_option( 'bogus' ),
            'aggregate->get_option(bogus) returns undef' );

    }

}
