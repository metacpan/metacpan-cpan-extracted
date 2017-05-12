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
        moniker   => 'IpBan',
    }
);
$schematest->methods(
    {
        columns => [
            qw[
                id
                ban_type_id
                ip_range
            ]
        ],

        relations => [
            qw[
                ban_type
            ]
        ],

        custom => [
            qw[
            ]
        ],

        resultsets => [
            qw[
                is_X_banned
                is_access_banned
                is_login_banned
                is_posting_banned
                is_signup_banned
            ]
        ],
    }
);

$schematest->run_tests();
