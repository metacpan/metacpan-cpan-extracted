#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw(no_plan);

BEGIN { require 't/utils.pl' }
RT::Init();

verbose("dead age");
{
    my $ticket = RT::Ticket->new( $RT::SystemUser );
    my ($id) = $ticket->Create( Queue => 'General', Status => 'resolved' );
    ok($id, "created ticket");

    my $date = $ticket->LastUpdatedObj;
    $date->AddDays( -70 );
    $ticket->__Set( Field => 'LastUpdated', Value => $date->ISO );
    is($ticket->LastUpdated, $date->ISO, 'set date' );

    my ($res, $err) = run_exec( debug => 1 );
    my $ferr = filter_log( $err );
    ok(!$ferr, 'no error') or diag $err;

    $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $id );
    is($ticket->id, $id, 'loaded ticket');
    is($ticket->FirstCustomFieldValue('Age'), 'Dead', 'correct age');
}

verbose("dead age: parent is finished while child is not");
{
    my $parent = RT::Ticket->new( $RT::SystemUser );
    my ($pid) = $parent->Create( Queue => 'General', Status => 'resolved' );
    ok($pid, "created parent ticket");

    my $date = $parent->LastUpdatedObj;
    $date->AddDays( -70 );
    $parent->__Set( Field => 'LastUpdated', Value => $date->ISO );
    is($parent->LastUpdated, $date->ISO, 'set date' );

    my $child = RT::Ticket->new( $RT::SystemUser );
    my ($cid) = $child->Create( Queue => 'General', MemberOf => $pid );
    ok($cid, "created child ticket");
    $child->__Set( Field => 'LastUpdated', Value => $date->ISO );
    is($child->LastUpdated, $date->ISO, 'set date' );

    my ($res, $err) = run_exec( debug => 1 );
    my $ferr = filter_log( $err );
    ok(!$ferr, 'no error') or diag($err);

    $parent->Load( $pid );
    is($parent->id, $pid, 'loaded ticket');
    is($parent->FirstCustomFieldValue('Age'), 'Active', 'correct age');

    $child->Load( $cid );
    is($child->id, $cid, 'loaded ticket');
    is($child->FirstCustomFieldValue('Age'), 'Active', 'correct age');
    is($child->LastUpdated, $date->ISO, 'set date' );
}

verbose("dead age: child is finished, but parent is not");
{
    my $parent = RT::Ticket->new( $RT::SystemUser );
    my ($pid) = $parent->Create( Queue => 'General' );
    ok($pid, "created parent ticket");

    my $date = $parent->LastUpdatedObj;
    $date->AddDays( -70 );
    $parent->__Set( Field => 'LastUpdated', Value => $date->ISO );
    is($parent->LastUpdated, $date->ISO, 'set date' );

    my $child = RT::Ticket->new( $RT::SystemUser );
    my ($cid) = $child->Create( Queue => 'General', MemberOf => $pid, Status => 'resolved' );
    ok($cid, "created child ticket");
    $child->__Set( Field => 'LastUpdated', Value => $date->ISO );
    is($child->LastUpdated, $date->ISO, 'set date' );

    $parent->Load( $pid );
    my $parent_date = $parent->LastUpdatedObj;

    my ($res, $err) = run_exec( debug => 1 );
    my $ferr = filter_log( $err );
    ok(!$ferr, 'no error') or diag($err);

    $parent->Load( $pid );
    is($parent->id, $pid, 'loaded ticket');
    is($parent->FirstCustomFieldValue('Age'), 'Active', 'correct age');
    is($parent->LastUpdated, $parent_date->ISO, 'correct date' );

    $child->Load( $cid );
    is($child->id, $cid, 'loaded child');
    is($child->FirstCustomFieldValue('Age'), 'Dead', 'correct age');
    is($child->LastUpdated, $date->ISO, 'correct date' );
}
