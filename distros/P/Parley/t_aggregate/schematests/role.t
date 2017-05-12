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
        moniker   => 'Role',
    }
);
$schematest->methods(
    {
        columns => [
            qw[
                id
                idx
                name
                description
            ]
        ],

        relations => [
            qw[
                map_user_role
            ]
        ],

        custom => [
            qw[
            ]
        ],

        resultsets => [
            qw[
                role_list
            ]
        ],
    }
);

$schematest->run_tests();
