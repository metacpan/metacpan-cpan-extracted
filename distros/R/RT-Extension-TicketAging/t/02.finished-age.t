#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw(no_plan);

BEGIN { require 't/utils.pl' }
RT::Init();

verbose("finished age");
{
    my $ticket = RT::Ticket->new( $RT::SystemUser );
    my ($id) = $ticket->Create( Queue => 'General', Status => 'resolved' );
    ok($id, "created ticket");

    run_exec_ok;

    $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $id );
    is($ticket->id, $id, 'loaded ticket');
    is($ticket->FirstCustomFieldValue('Age'), 'Finished', 'correct age');
}

verbose("finished age: child is resolved, parent is not");
{
    my $ticket = RT::Ticket->new( $RT::SystemUser );
    my ($pid) = $ticket->Create( Queue => 'General' );
    ok($pid, "created parent ticket");

    $ticket = RT::Ticket->new( $RT::SystemUser );
    my ($cid) = $ticket->Create( Queue => 'General', Status => 'resolved', MemberOf => $pid );
    ok($cid, "created child ticket");

    run_exec_ok;

    $ticket->Load( $pid );
    is($ticket->id, $pid, 'loaded ticket');
    is($ticket->FirstCustomFieldValue('Age'), 'Active', 'correct age');

    $ticket->Load( $cid );
    is($ticket->id, $cid, 'loaded ticket');
    is($ticket->FirstCustomFieldValue('Age'), 'Finished', 'correct age');
}

verbose("finished age: parent is resolved while child is not");
{
    my $ticket = RT::Ticket->new( $RT::SystemUser );
    my ($pid) = $ticket->Create( Queue => 'General', Status => 'resolved' );
    ok($pid, "created parent ticket");

    $ticket = RT::Ticket->new( $RT::SystemUser );
    my ($cid) = $ticket->Create( Queue => 'General', MemberOf => $pid );
    ok($cid, "created child ticket");

    run_exec_ok;

    $ticket->Load( $pid );
    is($ticket->id, $pid, 'loaded ticket');
    is($ticket->FirstCustomFieldValue('Age'), 'Active', 'correct age');

    $ticket->Load( $cid );
    is($ticket->id, $cid, 'loaded ticket');
    is($ticket->FirstCustomFieldValue('Age'), 'Active', 'correct age');
}

verbose("finished age: parent is resolved as all its children");
{
    my $ticket = RT::Ticket->new( $RT::SystemUser );
    my ($pid) = $ticket->Create( Queue => 'General', Status => 'resolved' );
    ok($pid, "created parent ticket");

    $ticket = RT::Ticket->new( $RT::SystemUser );
    my ($cid) = $ticket->Create( Queue => 'General', Status => 'resolved', MemberOf => $pid );
    ok($cid, "created child ticket");

    run_exec_ok;

    $ticket->Load( $pid );
    is($ticket->id, $pid, 'loaded ticket');
    is($ticket->FirstCustomFieldValue('Age'), 'Finished', 'correct age');

    $ticket->Load( $cid );
    is($ticket->id, $cid, 'loaded ticket');
    is($ticket->FirstCustomFieldValue('Age'), 'Finished', 'correct age');
}

