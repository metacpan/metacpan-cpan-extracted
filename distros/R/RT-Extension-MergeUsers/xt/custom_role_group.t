#!/usr/bin/perl

use strict;
use warnings;
use RT::Extension::MergeUsers::Test tests => undef;

# Scenario: a user-defined group is assigned to a custom role on a ticket.
# An unprivileged user with the same Name as the group is also present.
# TweakRoleLimitArgs (the MergeUsers hook around RoleLimit) must include the
# group's id in the search - not only the user's id - so the ticket is found.

my $queue = RT::Test->load_or_create_queue( Name => 'General' );

# Use $$ to get unique names that won't collide across parallel test runs.
my $role_name  = 'VendorRole-' . $$;
my $group_name = 'VendorCo-'   . $$;

my $role = RT::CustomRole->new( RT->SystemUser );
my ( $ok, $msg ) = $role->Create(
    Name      => $role_name,
    MaxValues => 0,
);
ok( $ok, "Created custom role '$role_name': $msg" );

( $ok, $msg ) = $role->AddToObject( $queue->id );
ok( $ok, "Applied '$role_name' role to General queue: $msg" );

my $vendor_group = RT::Test->load_or_create_group($group_name);
ok( $vendor_group && $vendor_group->id, "Created group '$group_name'" );

my $ticket = RT::Test->create_ticket(
    Queue   => $queue,
    Subject => 'Ticket with group in custom role',
);
( $ok, $msg ) = $ticket->AddWatcher(
    Type      => $role->GroupType,
    Principal => $vendor_group->PrincipalObj,
);
ok( $ok, "Assigned group '$group_name' to '$role_name' on ticket: $msg" );

# A second ticket with no custom role watcher - must never appear in results.
RT::Test->create_ticket(
    Queue   => $queue,
    Subject => 'Ticket without custom role watcher',
);

diag "Search by group name - no conflicting user exists yet";
{
    my $tix = RT::Tickets->new( RT->SystemUser );
    $tix->FromSQL(
        "Queue = 'General' AND CustomRole.{" . $role->id . "}.Name = '$group_name'"
    );
    is( $tix->Count, 1,
        "CustomRole.{ID}.Name = '$group_name' finds ticket with group in role" );

    $tix = RT::Tickets->new( RT->SystemUser );
    $tix->FromSQL(
        "Queue = 'General' AND 'CustomRole.{$role_name}.Name' = '$group_name'"
    );
    is( $tix->Count, 1,
        "CustomRole.{RoleName}.Name = '$group_name' finds ticket with group in role" );
}

diag "Create an unprivileged user whose Name matches the group";
{
    my $user = RT::User->new( RT->SystemUser );
    ( $ok, $msg ) = $user->Create(
        Name       => $group_name,
        Privileged => 0,
    );
    ok( $ok, "Created unprivileged user named '$group_name': $msg" );
    ok( !$user->Privileged, 'Confirmed user is unprivileged' );
}

diag "Search by group name - conflicting user now present";
{
    my $tix = RT::Tickets->new( RT->SystemUser );
    $tix->FromSQL(
        "Queue = 'General' AND CustomRole.{" . $role->id . "}.Name = '$group_name'"
    );
    is( $tix->Count, 1,
        "CustomRole.{ID}.Name = '$group_name' still finds ticket when user shares the group name"
    );

    $tix = RT::Tickets->new( RT->SystemUser );
    $tix->FromSQL(
        "Queue = 'General' AND 'CustomRole.{$role_name}.Name' = '$group_name'"
    );
    is( $tix->Count, 1,
        "CustomRole.{RoleName}.Name = '$group_name' still finds ticket when user shares the group name"
    );
}

diag "User is the role member, a group shares the user's name - positive search still works";
{
    my $shared_name = 'UserWithGroupName-' . $$;

    my $role2 = RT::CustomRole->new( RT->SystemUser );
    ( $ok, $msg ) = $role2->Create(
        Name      => 'Role2-' . $$,
        MaxValues => 0,
    );
    ok( $ok, "Created second custom role: $msg" );
    ( $ok, $msg ) = $role2->AddToObject( $queue->id );
    ok( $ok, "Applied second role to General queue: $msg" );

    my $shared_name_group = RT::Test->load_or_create_group($shared_name);
    ok( $shared_name_group && $shared_name_group->id,
        "Created group '$shared_name'" );

    my $shared_name_user = RT::User->new( RT->SystemUser );
    ( $ok, $msg ) = $shared_name_user->Create(
        Name       => $shared_name,
        Privileged => 0,
    );
    ok( $ok, "Created user '$shared_name': $msg" );

    my $user_ticket = RT::Test->create_ticket(
        Queue   => $queue,
        Subject => 'Ticket with user (not group) in custom role',
    );
    ( $ok, $msg ) = $user_ticket->AddWatcher(
        Type      => $role2->GroupType,
        Principal => $shared_name_user->PrincipalObj,
    );
    ok( $ok, "Assigned user '$shared_name' to role2 on ticket: $msg" );

    # The search by Name should find the ticket where the USER is the role member,
    # even though a group with the same name also exists.
    my $tix = RT::Tickets->new( RT->SystemUser );
    $tix->FromSQL(
        "Queue = 'General' AND CustomRole.{" . $role2->id . "}.Name = '$shared_name'"
    );
    is( $tix->Count, 1,
        "CustomRole.{ID}.Name = '$shared_name' finds ticket with user in role (group shares name)" );

    # The group is not a role member, so no additional tickets should appear.
    my $found_ticket = $tix->First;
    is( $found_ticket->id, $user_ticket->id,
        "Found ticket is the one with the user as role member, not a false positive from the group" );
    isnt( $found_ticket->id, $ticket->id,
        "Ticket from scenario 1 (group in role1) is not a false positive in role2 search" );
}

diag "Merged-user expansion still works alongside the group fix";
{
    my $primary = RT::User->new( RT->SystemUser );
    ( $ok, $msg ) = $primary->Create(
        Name         => 'primary-merged-' . $$,
        EmailAddress => "primary-merged-$$\@example.com",
        Privileged   => 0,
    );
    ok( $ok, "Created primary user: $msg" );

    my $secondary = RT::User->new( RT->SystemUser );
    ( $ok, $msg ) = $secondary->Create(
        Name         => 'secondary-merged-' . $$,
        EmailAddress => "secondary-merged-$$\@example.com",
        Privileged   => 0,
    );
    ok( $ok, "Created secondary user: $msg" );

    ( $ok, $msg ) = $secondary->MergeInto($primary);
    ok( $ok, "Merged secondary into primary: $msg" );

    my $merged_ticket = RT::Test->create_ticket(
        Queue   => $queue,
        Subject => 'Ticket for merged-user role test',
    );
    ( $ok, $msg ) = $merged_ticket->AddWatcher(
        Type      => $role->GroupType,
        Principal => $primary->PrincipalObj,
    );
    ok( $ok, "Assigned primary user to '$role_name' on ticket: $msg" );

    # Searching by primary email finds the ticket.
    my $tix = RT::Tickets->new( RT->SystemUser );
    $tix->FromSQL(
        "Queue = 'General' AND CustomRole.{" . $role->id
            . "}.EmailAddress = 'primary-merged-$$\@example.com'"
    );
    is( $tix->Count, 1,
        "CustomRole.{ID}.EmailAddress search finds ticket via primary user" );

    # Searching by secondary (merged-away) email also finds the ticket.
    $tix = RT::Tickets->new( RT->SystemUser );
    $tix->FromSQL(
        "Queue = 'General' AND CustomRole.{" . $role->id
            . "}.EmailAddress = 'secondary-merged-$$\@example.com'"
    );
    is( $tix->Count, 1,
        "CustomRole.{ID}.EmailAddress search finds ticket via secondary (merged) user email" );

    # Searching by secondary name finds the ticket.
    $tix = RT::Tickets->new( RT->SystemUser );
    $tix->FromSQL(
        "Queue = 'General' AND CustomRole.{" . $role->id
            . "}.Name = 'secondary-merged-$$'"
    );
    is( $tix->Count, 1,
        "CustomRole.{ID}.Name search finds ticket via secondary (merged) user name" );
}

done_testing;
