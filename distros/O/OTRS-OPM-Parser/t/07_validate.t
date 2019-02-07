#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use OTRS::OPM::Parser;

use File::Basename;
use File::Spec;

{
    my $opm_file = File::Spec->catfile( dirname(__FILE__), 'data', 'NotThere-3.3.2.opm' );
    my $opm      = OTRS::OPM::Parser->new( opm_file => $opm_file );

    isa_ok $opm, 'OTRS::OPM::Parser';

    my $success = $opm->validate;

    ok !$success, 'File NotThere-3.3.2.opm does not exist';
    is $opm->error_string, 'File does not exist';
}

{
    my $opm_file = File::Spec->catfile( dirname(__FILE__), 'data', 'QuickMergeInvalid-3.3.2.opm' );
    my $opm      = OTRS::OPM::Parser->new( opm_file => $opm_file );

    isa_ok $opm, 'OTRS::OPM::Parser';

    my $success = $opm->validate;

    ok !$success, 'Could not parse QuickMergeInvalid-3.3.2.opm';
    like $opm->error_string, qr/Could not parse/, 'error_string (QuickMergeInvalid-3.3.2.opm)';
}

{
    my $opm_file = File::Spec->catfile( dirname(__FILE__), 'data', 'QuickMergeInvalid-3.3.3.opm' );
    my $opm      = OTRS::OPM::Parser->new( opm_file => $opm_file );

    isa_ok $opm, 'OTRS::OPM::Parser';

    my $success = $opm->validate;

    ok !$success, 'Could not validate QuickMergeInvalid-3.3.3.opm';
    like $opm->error_string, qr/Could not validate/, 'error_string (QuickMergeInvalid-3.3.3.opm)';
}

{
    my $opm_file = File::Spec->catfile( dirname(__FILE__), 'data', 'QuickMergeInvalid-3.3.4.opm' );
    my $opm      = OTRS::OPM::Parser->new( opm_file => $opm_file );

    isa_ok $opm, 'OTRS::OPM::Parser';

    my $success = $opm->validate;

    ok !$success, 'Could not validate QuickMergeInvalid-3.3.4.opm';
    like $opm->error_string, qr/Could not validate/, 'error_string (QuickMergeInvalid-3.3.4.opm)';
#    is $opm->error_string, '';
}

{
    my $opm_file = File::Spec->catfile( dirname(__FILE__), 'data', 'QuickMerge-4.0.3.opm' );
    my $opm      = OTRS::OPM::Parser->new( opm_file => $opm_file );

    isa_ok $opm, 'OTRS::OPM::Parser';

    my $success = $opm->validate;

    SKIP: {
        skip 'Old XSD version', 2 if $opm->error_string =~ m{Invalid value for maxOccurs};

        is $success, 1, 'can validate QuickMerge-4.0.3.opm';
        is $opm->error_string, '', 'No error when validating QuickMerge-4.0.3.opm';
    }
}

{
    no warnings 'redefine';
    local *OTRS::OPM::Parser::_get_xsd = sub {

    return q~<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified">
    <xs:import namespace="http://www.w3.org/XML/1998/namespace"/>
    
    <xs:element name="otrs_package">
        <xs:complexType>
            <xs:all>
                <xs:element ref="Name" minOccurs="0" maxOccurs="1"/>
            </xs:all>
            <xs:attribute name="version" use="required" type="xs:anySimpleType"/>
        </xs:complexType>
    </xs:element>

    <xs:element name="Name" type="xs:token"/>
</xs:schema>
~;
    };

    my $opm_file = File::Spec->catfile( dirname(__FILE__), 'data', 'validate.opm' );
    my $opm      = OTRS::OPM::Parser->new( opm_file => $opm_file );

    isa_ok $opm, 'OTRS::OPM::Parser';

    my $success = $opm->validate;
    is $success, 1;
    is $opm->error_string, '';
}

done_testing();

