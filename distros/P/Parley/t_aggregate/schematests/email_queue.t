#!/usr/bin/perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

# load the module that provides all of the common test functionality
use FindBin qw($Bin);
use lib $Bin;
use SchemaTest;

my $schematest = SchemaTest->new(
    {
        dsn       => 'dbi:Pg:dbname=parley',
        namespace => 'Parley::Schema',
        moniker   => 'EmailQueue',
    }
);
$schematest->methods(
    {
        columns => [
            qw[
                id
                queued
                recipient_id
                cc_id
                bcc_id
                sender
                subject
                text_content
                html_content
                attempted_delivery
            ]
        ],

        relations => [
            qw[
                recipient
                cc
                bcc
            ]
        ],

        custom => [
            qw[
            ]
        ],

        resultsets => [
            qw[
            ]
        ],
    }
);

$schematest->run_tests();
