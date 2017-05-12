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
        dsn         => 'dbi:Pg:dbname=parley',
        username    => 'parley',
        namespace   => 'Parley::Schema',
        moniker     => 'Person',
    }
);
$schematest->methods(
    {
        columns => [
            qw[
                id
                authentication_id
                first_name
                last_name
                email
                forum_name
                preference_id
                last_post_id
                post_count
                suspended
            ]
        ],

        relations => [
            qw[
                threads
                email_queues
                thread_views
                preference
                last_post
                authentication
                registration_authentications
            ]
        ],

        custom => [
            qw[
                roles
                check_user_roles
                check_any_user_role
                is_site_moderator
                can_suspend_account
                last_suspension
                can_ip_ban
                can_view_site_menu
                can_moderate_forum
                set_suspended
                posts_from_ip
            ],
        ],

        resultsets => [
            qw[
                users_with_roles
            ]
        ],
    }
);

$schematest->run_tests();
