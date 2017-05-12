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
use NetApp::Qtree;

foreach my $filer_args ( @NetApp::Test::filer_args ) {

    ok( ref $filer_args eq 'HASH',
        'filer_args entry is a HASH ref' );

    my $filer		= NetApp::Filer->new( $filer_args );
    isa_ok( $filer, 'NetApp::Filer' );

    print "# Running tests on filer " . $filer->get_hostname . "\n";

    my @qtrees		= $filer->get_qtrees;
    ok( @qtrees,	'filer->get_qtrees' );

    foreach my $qtree ( @qtrees ) {

        isa_ok( $qtree,			'NetApp::Qtree' );
        isa_ok( $qtree->get_filer,	'NetApp::Filer' );

        my $volume_name		= $qtree->get_volume_name;
        ok( $volume_name,	'qtree->get_volume_name' );

        # $filer->_dump_volume_cache;

        my $volume0		= $qtree->get_volume;
        isa_ok( $volume0,	'NetApp::Volume' );

        my $volume_name0	= $volume0->get_name;

        # $filer->_dump_volume_cache;

        my $volume		= $qtree->get_volume;
        isa_ok( $volume,	'NetApp::Volume' );

        my $volume_name1	= $volume->get_name;

        ok( $volume_name0 eq $volume_name1,
            'cache returns the same object both times' );

        # $filer->_dump_volume_cache;

        if ( $volume->get_status( 'flex' ) ) {
            isa_ok( $qtree->get_aggregate, 	'NetApp::Aggregate' );
        }

        my $name		= $qtree->get_name;
        my $security		= $qtree->get_security;
        my $oplocks		= $qtree->get_oplocks;
        my $status		= $qtree->get_status;
        my $id			= $qtree->get_id;
        my $vfiler		= $qtree->get_vfiler;

        ok( $name		=~ m:^/vol/:,
            "qtree->get_name: $name" );
        ok( $security 	=~ /^(unix|ntfs|mixed)$/,
            "qtree->get_security: $security" );
        ok( $oplocks == 0 || $oplocks == 1,
            "qtree->get_oplocks: $oplocks" );
        ok( $status 	=~ /^(normal|snap.*)$/,
            "qtree->get_status: $status" );
        ok( $id 		=~ /^\d+$/,
            "qtree->get_id: $id" );
        ok( $vfiler,
            "qtree->get_vfiler: $vfiler" );

    }

    foreach my $aggregate ( $filer->get_aggregates ) {

        my $aggregate_name	= $aggregate->get_name;

        # XXX: These are not supported correctly
        if ( $aggregate->get_status( 'trad' ) ) {
            print "# Skipping traditional aggregate $aggregate_name\n";
            next;
        }

        my @volumes		= $aggregate->get_volumes;

        if ( not @volumes ) {
            print "# Skipping aggregate $aggregate_name, it has no volumes\n";
            next;
        }

        print "# Checking qtrees on $aggregate_name\n";

        my @aggr_qtree_names	= $aggregate->get_qtree_names;
        ok( @aggr_qtree_names,  'aggregate->get_qtree_names' );

        my @aggr_qtrees		= $aggregate->get_qtrees;
        ok ( @aggr_qtrees, 	'aggregate->get_qtrees' );

        ok( $#aggr_qtrees == $#aggr_qtree_names,
            'same number of qtree objects and names in aggregate' );

        foreach my $qtree_name ( @aggr_qtree_names ) {
            my $qtree	= $aggregate->get_qtree( $qtree_name );
            ok( ref $qtree && $qtree->isa('NetApp::Qtree'),
                "aggregate->get_qtree( $qtree_name )" );
        }

        foreach my $volume ( @volumes ) {

            my $volume_name	= $volume->get_name;

            if ( $volume->get_state('restricted') ) {
                print "# Skipping restricted volume $volume_name\n";
                next;
            }

            print "# Checking qtrees on volume $volume_name\n";

            my @vol_qtree_names	= $volume->get_qtree_names;
            ok( @vol_qtree_names, 'volume->get_qtree_names' );

            my @vol_qtrees	= $volume->get_qtrees;
            ok( @vol_qtrees,	'volume->get_qtrees' );

            ok( $#vol_qtrees == $#vol_qtree_names,
                'same number of qtree objects and names in volume' );

            foreach my $qtree_name ( @vol_qtree_names ) {
                my $qtree	= $volume->get_qtree( $qtree_name );
                ok( ref $qtree && $qtree->isa('NetApp::Qtree'),
                    "volume->get_qtree( $qtree_name )" );
            }

            my $vol_qtree	= $volume->get_qtree;
            isa_ok( $vol_qtree,	'NetApp::Qtree' );

            ok( ref $vol_qtree &&
                    $vol_qtree->get_name eq "/vol/" . $volume->get_name,
                'volume->get_qtree returns the volume qtree' );

        }

    }

}
