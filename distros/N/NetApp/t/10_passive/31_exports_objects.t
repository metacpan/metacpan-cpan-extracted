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

    my @exports		= $filer->get_exports;
    ok( @exports,		'filer->get_exports' );

    my %exports		= map { $_ => 0 } qw( permanent temporary
                                              active inactive );

    foreach my $export ( @exports ) {

        isa_ok( $export,
                'NetApp::Filer::Export' );

        isa_ok( $export->get_filer,
                'NetApp::Filer' );

        my $type		= $export->get_type;
        ok( ( grep { $type eq $_ } qw( permanent temporary ) ),
            "export->get_type: '$type'" );
        $exports{ $type }++;

        my $active		= $export->get_active;
        ok( defined $active,
            "export->get_active: '$active'" );
        $exports{ $active ? 'active' : 'inactive' }++;

        my $path		= $export->get_path;
        ok( $path =~ qr{^/vol/},
            "export->get_path: '$path'" );

        my $actual		= $export->get_actual;
        if ( $actual ) {
            ok( $actual =~ qr{^/vol/},
                "export->get_actual: '$actual'" );
        }

        my $nosuid		= $export->get_nosuid;
        ok( defined $nosuid,
            "export->get_nosuid: '$nosuid'" );

        foreach my $sec ( $export->get_sec ) {
            ok( ( grep { $sec eq $_ } qw( none sys krb5 krb5i krb5p ) ),
                "export->get_sec value: '$sec'" );
        }

        foreach my $root ( $export->get_root ) {
            ok( defined $root,
                "export->get_root value: '$root'" );
        }

        if ( $export->get_rw_all ) {
            if ( my $rw	= join ':', $export->get_rw ) {
                ok( 0, "export->get_rw returns bogus value: '$rw'" );
            } else {
                ok( 1, "export->get_rw returns nothing" );
            }
        }

        if ( $export->get_ro_all ) {
            if ( my $ro	= join ':', $export->get_ro ) {
                ok( 0, "export->get_ro returns bogus value: '$ro'" );
            } else {
                ok( 1, "export->get_ro returns nothing" );
            }
        }

    }

    my @permanent	= $filer->get_permanent_exports;
    my @temporary	= $filer->get_temporary_exports;
    my @active	= $filer->get_active_exports;
    my @inactive	= $filer->get_inactive_exports;

    ok( $exports{permanent} == scalar @permanent,
        "filer->get_permanent_exports scalar value: " . ($#permanent+1) );
    ok( $exports{temporary} == scalar @temporary,
        "filer->get_temporary_exports scalar value: " . ($#temporary+1) );
    ok( $exports{active} == scalar @active,
        "filer->get_active_exports scalar value: " . ($#active+1) );
    ok( $exports{inactive} == scalar @inactive,
        "filer->get_inactive_exports scalar value: " . ($#inactive+1) );

}
