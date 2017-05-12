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
        moniker   => 'Thread',
    }
);
$schematest->methods(
    {
        columns => [
            qw[
                id
                forum_id
                subject
                created
                creator_id
                post_count
                view_count
                active
                sticky
                locked
                last_post_id
            ]
        ],

        relations => [
            qw[
                last_post
                posts
                thread_views
                forum_moderators
            ]
        ],

        custom => [
            qw[
            ]
        ],

        resultsets => [
            qw[
                last_post_viewed_in_thread
                recent
                record_from_id
            ]
        ],
    }
);

$schematest->run_tests();
