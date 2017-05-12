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
        moniker   => 'Post',
    }
);
$schematest->methods(
    {
        columns => [
            qw[
                id
                creator_id
                subject
                quoted_post_id
                message
                quoted_text
                created
                thread_id
                reply_to_id
                edited
                ip_addr
                admin_editor_id
                locked
            ]
        ],

        relations => [
            qw[
                threads
                forums
                creator
                reply_to
                post_reply_toes
                thread
                quoted_post
                post_quoted_posts
                people
                admin_editor
            ]
        ],

        custom => [
            qw[
                match_context
                interval_ago
            ]
        ],

        resultsets => [
            qw[
                record_from_id
                people_posting_from_ip
                last_post_in_list
                next_post
                page_containing_post
                thread_position
            ]
        ],
    }
);

$schematest->run_tests();
