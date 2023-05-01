#!/usr/bin/env perl

package Quiq::DataStructure::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::DataStructure');
}

# -----------------------------------------------------------------------------

sub test_validate : Test(0) {
    my $self = shift;

    # Struktur mit alle zulässigen Komponenten

    my $ref0 = {
        debug => 0,
        name => 'Ad-hoc_4711_Beispiel',
        file => 'Ad-hoc_4711_Beispiel.xlsx',
        mail => {
            from => 'ZBM-ITBI_ADHOC@zeppelin.com',
            to => [
                'Frank Seitz <frank.seitz.external@zeppelin.com',
                # ...
            ],
            subject => 'Ad-hoc_4711',
            body => q~
                Dies ist eine automatisch generierte Mail.
            ~,
        },
        worksheets => [
            benutzer => {
                title => 'Benutzer',
                select => q~
                    SELECT
                        jutx40
                    FROM
                        cmnusr
                    WHERE
                        jutx40 LIKE 'A%'
                    ORDER BY
                        jutx40;
                ~,
                columns => [
                    juusid => {
                        title => 'Kürzel',
                        type => 'STRING',
                        width => 20,
                    },
                    # ...
                ],
            },
            # ...
        ],
    };

    # Teilstruktur

    my $ref1 = {
        debug => 0,
        mail => {
            to => [
                'frank.seitz.external@zeppelin.com',
            ],
        },
        worksheets => [
            benutzer => {
                title => 'Benutzer A...',
                select => q~
                    SELECT
                        jutx40
                        , juusid
                    FROM
                        cmnusr
                    WHERE
                        jutx40 LIKE 'A%'
                    ORDER BY
                        jutx40
                ~,
                columns => [
                    jutx40 => {
                        title => 'Benutzername',
                        type => 'STRING',
                        width => 30,
                    },
                    juusid => {
                        title => 'Kürzel',
                        type => 'STRING',
                        width => 10,
                    },
                ],
            },
        ],
    };

    Quiq::DataStructure->validate($ref0,$ref1,1);
}

# -----------------------------------------------------------------------------

package main;
Quiq::DataStructure::Test->runTests;

# eof
