#!/usr/bin/perl

use strict;
use warnings;

use RT::Extension::SLA::Test tests => 35;

note 'check that reply to requestors dont unset due date with KeepInLoop';
{
    %RT::ServiceAgreements = (
        Default => '2',
        Levels => {
            '2' => {
                KeepInLoop => { RealMinutes => 60*4, IgnoreOnStatuses => ['stalled'] },
            },
        },
    );

    my $root = RT::User->new( $RT::SystemUser );
    $root->LoadByEmail('root@localhost');
    ok $root->id, 'loaded root user';

    # requestor creates
    my $id;
    my $due;
    {
        my $ticket = RT::Ticket->new( $root );
        ($id) = $ticket->Create(
            Queue => 'General',
            Subject => 'xxx',
            Requestor => $root->id,
        );
        ok $id, "created ticket #$id";
        is $ticket->FirstCustomFieldValue('SLA'), '2', 'default sla';
        ok !$ticket->DueObj->Unix, 'no response deadline';
        $due = 0;
    }

    # non-requestor reply
    {
        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok $ticket->id, "loaded ticket #$id";
        $ticket->Correspond( Content => 'we are working on this.' );

        $ticket = RT::Ticket->new( $root );
        $ticket->Load( $id );
        ok $ticket->id, "loaded ticket #$id";

        my $tmp = $ticket->DueObj->Unix;
        ok $tmp > 0, 'Due date is set';
        ok $tmp > $due, "keep in loop is 4hours when response is 2hours";
        $due = $tmp;
    }

    # stalling ticket
    {
        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok $ticket->id, "loaded ticket #$id";
        my ($status, $msg) = $ticket->SetStatus('stalled');
        ok $status, 'stalled the ticket';

        $ticket->Load( $id );
        ok !$ticket->DueObj->Unix, 'keep in loop deadline ignored for stalled';
    }

    # non-requestor reply again
    {
        sleep 1;
        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok $ticket->id, "loaded ticket #$id";
        $ticket->Correspond( Content => 'we are still working on this.' );
        $ticket->SetStatus('open');

        $ticket = RT::Ticket->new( $root );
        $ticket->Load( $id );
        ok $ticket->id, "loaded ticket #$id";

        is $ticket->Status, 'open', 'ticket was opened';

        my $tmp = $ticket->DueObj->Unix;
        ok $tmp > 0, 'Due date is set';
        ok $tmp > $due, "keep in loop sligtly moved";
        $due = $tmp;
    }
}

note 'Check that failing to reply to the requestors is not ignored';
{
    %RT::ServiceAgreements = (
        Default => '2',
        Levels => {
            '2' => {
                Response   => { RealMinutes => 60*2 },
                KeepInLoop => { RealMinutes => 60*4, IgnoreOnStatuses => ['stalled'] },
            },
        },
    );

    my $root = RT::User->new( $RT::SystemUser );
    $root->LoadByEmail('root@localhost');
    ok $root->id, 'loaded root user';

    # requestor creates
    my $id;
    my $due;
    {
        my $ticket = RT::Ticket->new( $root );
        ($id) = $ticket->Create(
            Queue => 'General',
            Subject => 'xxx',
            Requestor => $root->id,
        );
        ok $id, "created ticket #$id";
        is $ticket->FirstCustomFieldValue('SLA'), '2', 'default sla';
        $due = $ticket->DueObj->Unix;
        ok $due > 0, 'response deadline';
    }

    # stalling ticket
    {
        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok $ticket->id, "loaded ticket #$id";
        my ($status, $msg) = $ticket->SetStatus('stalled');
        ok $status, 'stalled the ticket';

        $ticket->Load( $id );
        my $tmp = $ticket->DueObj->Unix;
        ok $tmp, 'response deadline not unset';
        is $tmp, $due, 'due not changed';
    }

    # non-requestor reply
    {
        sleep 1;
        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok $ticket->id, "loaded ticket #$id";
        $ticket->Correspond( Content => 'we are still working on this.' );
        $ticket->SetStatus('open');

        $ticket = RT::Ticket->new( $root );
        $ticket->Load( $id );
        ok $ticket->id, "loaded ticket #$id";

        is $ticket->Status, 'open', 'ticket was opened';

        my $tmp = $ticket->DueObj->Unix;
        ok $tmp > 0, 'Due date is set';
        ok $tmp > $due, "keep in loop is greater than response";
        $due = $tmp;
    }

    # stalling ticket again
    {
        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok $ticket->id, "loaded ticket #$id";
        my ($status, $msg) = $ticket->SetStatus('stalled');
        ok $status, 'stalled the ticket';

        $ticket->Load( $id );
        ok !$ticket->DueObj->Unix, 'keep in loop deadline unset for stalled';
    }
}
