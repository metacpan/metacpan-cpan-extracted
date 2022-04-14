#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use OPM::Parser;

use File::Basename;
use File::Spec;

{
    my $opm_file = File::Spec->catfile( dirname(__FILE__), 'data', 'QuickMergeOtobo-4.0.3.opm' );
    my $opm      = OPM::Parser->new( opm_file => $opm_file );

    isa_ok $opm, 'OPM::Parser';

    my $success = $opm->validate;

    SKIP: {
        skip 'Old XSD version', 2 if $opm->error_string =~ m{Invalid value for maxOccurs};

        is $success, 1, 'can validate QuickMergeOtobo-4.0.3.opm';
        is $opm->error_string, '', 'No error when validating QuickMergeOtobo-4.0.3.opm';
    }
}

done_testing();

