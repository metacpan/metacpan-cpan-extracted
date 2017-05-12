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

foreach my $filer_args ( @NetApp::Test::filer_args ) {

    ok( ref $filer_args eq 'HASH',
        'filer_args entry is a HASH ref' );

    my $filer		= NetApp::Filer->new( $filer_args );
    isa_ok( $filer, 'NetApp::Filer' );

    print "# Running tests on filer " . $filer->get_hostname . "\n";

    my $version		= $filer->get_version;
    isa_ok( $version,	'NetApp::Filer::Version' );

    my @licenses	= $filer->get_licenses;
    ok( @licenses,	'filer->get_licenses' );

    foreach my $license ( @licenses ) {
        ok( $license->get_service,	'license->get_service' );
        ok( $license->get_type,		'license->get_type' );
        ok( $license->get_code,		'license->get_code' );
        ok( defined $license->get_expired, 'license->get_expired' );
    }

    my @options		= $filer->get_options;
    ok( @options,	'filer->get_options' );

    foreach my $option ( @options ) {
        ok( $option->get_name,		'option->get_name' );
        ok( defined $option->get_value,	'option->get_value' );
    }

}
