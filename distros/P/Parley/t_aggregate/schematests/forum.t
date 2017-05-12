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
        moniker   => 'Forum',
    }
);
$schematest->methods(
    {
        columns => [
            qw[
                id
                name
                description
                active
                post_count
                last_post_id
            ]
        ],

        relations => [
            qw[
                threads
                last_post
            ]
        ],

        custom => [
            qw[
                moderators
            ]
        ],

        resultsets => [
            qw[
                available_list
                record_from_id
            ]
        ],
    }
);

$schematest->run_tests();
