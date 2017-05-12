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
        moniker   => 'ThreadView',
    }
);
$schematest->methods(
    {
        columns => [
            qw[
                id
                person_id
                thread_id
                timestamp
                watched
                last_notified
            ]
        ],

        relations => [
            qw[
                thread
                person
            ]
        ],

        custom => [
            qw[
                interval_ago
            ]
        ],

        resultsets => [
            qw[
                watching_thread
                notification_list
            ]
        ],
    }
);

$schematest->run_tests();
