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
use NetApp::Snapshot;

my %tested		= ();

foreach my $filer_args ( @NetApp::Test::filer_args ) {

    ok( ref $filer_args eq 'HASH',
        'filer_args entry is a HASH ref' );

    %tested		= ();

    my $filer		= NetApp::Filer->new( $filer_args );
    isa_ok( $filer, 'NetApp::Filer' );

    print "# Running tests on filer " . $filer->get_hostname . "\n";

    my @aggregates	= $filer->get_aggregates;

    foreach my $aggregate ( @aggregates ) {

        test_parent( $aggregate );

        my $aggregate_name	= $aggregate->get_name;

        if ( $aggregate->get_status( 'trad' ) ) {
            print "# Skipping traditional aggregate $aggregate_name\n";
            next;
        }

        my @volumes		= $aggregate->get_volumes;

        foreach my $volume ( @volumes ) {

            my $volume_name	= $volume->get_name;

            if ( $volume->get_status( 'offline' ) ) {
                print "# Skipping tests for offline volume $volume_name\n";
                next;
            }

            if ( $volume->get_state('restricted') ) {
                print "# Skipping tests for restricted volume $volume_name\n";
                next;
            }

            test_parent( $volume );

        }

    }

}

sub test_parent {

    my $object		= shift;

    my $object_class	= ref $object;
    my $object_name	= $object->get_name;

    my $filer_name	= $object->get_filer->get_hostname;

    if ( exists $tested{$object_class} && $tested{$object_class} >= 3 ) {
        print "# Skipping further tests for $object_class on $filer_name\n";
        return 1;
    }

    print "# Testing snapshot API for $object_class $object_name\n";

    my $reserved	= $object->get_snapshot_reserved;

    ok( defined $reserved,
        'object->get_snapshot_reserved' );

    my $schedule	= $object->get_snapshot_schedule;

    isa_ok( $schedule,	'NetApp::Snapshot::Schedule' );

    my $schedule_parent	= $schedule->get_parent;
    ok( $schedule_parent->get_name eq $object->get_name,
        'schedule parent name is correct' );

    ok( $schedule->get_weekly =~ /^\d+$/,
        'schedule->get_weekly correct: ' . $schedule->get_weekly );
    ok( $schedule->get_daily =~ /^\d+$/,
        'schedule->get_daily correct: ' . $schedule->get_daily );
    ok( $schedule->get_hourly =~ /^\d+$/,
        'schedule->get_hourly correct: ' . $schedule->get_hourly );

    foreach my $hour ( $schedule->get_hourlist ) {
        ok( $hour =~ /^\d+$/, "hourlist value correct: $hour" );
    }

    my @snapshots	= $object->get_snapshots;

    foreach my $snapshot ( @snapshots ) {

        my $parent	= $snapshot->get_parent;
        my $snapshot_name = $snapshot->get_name;

        if ( $snapshot_name =~ /\(\d+\)/ ) {
            print "# Skipping transient snapshot $snapshot_name\n";
            next;
        } else {
            print "# Testing snapshot $object_name:$snapshot_name\n";
        }

        ok( $parent->get_name eq $object->get_name,
            'snapshot parent name is correct' );

        ok( $snapshot->get_name,
            'snapshot->get_name: ' . $snapshot->get_name );
        ok( $snapshot->get_date =~ /^\S+\s+\d+\s+\d+:\d+$/,
            'snapshot->get_date: ' . $snapshot->get_date );
        ok( $snapshot->get_used =~ /^\d+$/,
            'snapshot->get_used: ' . $snapshot->get_used );
        ok( $snapshot->get_total =~ /^\d+$/,
            'snapshot->get_total: ' . $snapshot->get_total );

        # XXX: We're getting burned by transient snapshots...
        if ( $parent->isa("NetApp::Volume") ) {
            my $reclaimable	= $snapshot->get_reclaimable;
            if ( defined $reclaimable ) {
                ok( $reclaimable =~ /^\d+$/,
                    'snapshot->get_reclaimable: ' . $reclaimable );
            }
        }

        $tested{$object_class}++;

        my @deltas	= $snapshot->get_snapshot_deltas;

        foreach my $delta ( @deltas ) {
            isa_ok( $delta,	'NetApp::Snapshot::Delta' );
            if ( $delta->is_summary ) {
                ok( $delta->get_from eq $snapshot->get_name,
                    'summary delta from name matches snapshot name' );
            }
            $tested{$object_class}++;
        }

    }

    my @deltas		= $object->get_snapshot_deltas;

    my $found_summary	= 0;

    foreach my $delta ( @deltas ) {

        my $from	= $delta->get_from;
        my $to		= $delta->get_to;
        my $changed	= $delta->get_changed;
        my $time	= $delta->get_time;
        my $rate	= $delta->get_rate;

        ok( $from,      "delta->get_from: $from" );
        ok( $to,        "delta->get_to: $to" );
        ok( $changed =~ /^\d+$/,
            "delta->get_changed: $changed" );
        ok( $time =~ /^\d+d\s+\d+:\d+$/ || $time =~ /^\d+s$/,
            "delta->get_time: $time" );
        ok( $rate =~ /^[\d.]+$/,
            "delta->get_rate: $rate" );

        if ( $delta->is_summary ) {
            $found_summary	= 1;
        }

    }

    if ( @deltas ) {
        ok( $found_summary,
            'found a summary delta in the list' );
        $tested{$object_class}++;
    }
    
}
