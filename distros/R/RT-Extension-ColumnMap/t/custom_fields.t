#!/usr/bin/perl

use strict;
use warnings;

use RT::Extension::ColumnMap::Test tests => 8;

my $queue;
{
    $queue = RT::Test->load_or_create_queue( Name => 'General' );
    ok($queue && $queue->id, "loaded or created queue");
}

my $cf;
{
    $cf = RT::CustomField->new( $RT::SystemUser );
    my ($ret, $msg) = $cf->Create(
        Name  => 'Test',
        Queue => $queue->id,
        Type  => 'FreeformSingle',
    );
    ok($ret, "Custom Field Order created");
}

{
    my $ticket = RT::Ticket->new($RT::SystemUser);
    my ($tid, $msg) = $ticket->Create(
        Queue => $queue->id, Subject => 'test'
    );
    ok( RT::Extension::ColumnMap->Check(
        String => 'CustomField.{"Test"}.Content',
        Objects => {'' => $ticket},
        Checker => sub { !defined $_[0] },
    ), "checked CF" );

    (my $status, $msg) = $ticket->AddCustomFieldValue(
        Field => $cf->id,
        Value => 'test',
    );
    ok( $status, "changed CF" );

    ok( RT::Extension::ColumnMap->Check(
        String => 'CustomField.{"Test"}.Content',
        Objects => {'' => $ticket},
        Checker => sub { $_[0] eq 'test' },
    ), "checked CF" );
}


