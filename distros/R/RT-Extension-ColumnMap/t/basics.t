#!/usr/bin/perl

use strict;
use warnings;

use RT::Extension::ColumnMap::Test tests => 8;

{
    my $ticket = RT::Ticket->new($RT::SystemUser);
    my ($tid, $msg) = $ticket->Create(
        Queue => 'General', Subject => 'test'
    );
    ok( RT::Extension::ColumnMap->Check(
        String => 'Subject',
        Objects => {'' => $ticket},
        Checker => sub { $_[0] eq 'test'},
    ), "checked subject" );

    ok( RT::Extension::ColumnMap->Check(
        String => 'Owner.id',
        Objects => {'' => $ticket},
        Checker => sub { $_[0] eq $RT::Nobody->id },
    ), "checked subject" );
    ok( RT::Extension::ColumnMap->Check(
        String => 'Owner.Name',
        Objects => {'' => $ticket},
        Checker => sub { $_[0] eq 'Nobody' },
    ), "checked subject" );
    ok( RT::Extension::ColumnMap->Check(
        String => 'Owner',
        Objects => {'' => $ticket},
        Checker => sub { $_[0] eq 'Nobody' },
    ), "checked subject" );

    ok( RT::Extension::ColumnMap->Check(
        String => 'Ticket.Owner.Name',
        Objects => {'Ticket' => $ticket},
        Checker => sub { $_[0] eq 'Nobody' },
    ), "checked" );
}


