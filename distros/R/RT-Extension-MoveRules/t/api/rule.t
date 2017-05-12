#!/usr/bin/env perl

use strict;
use warnings;

use RT::Extension::MoveRules::Test tests => 15;

RT->Config->Set(
    'MoveRules' =>
    {
        From => 'From',
        To   => 'To',
        Rule => 'Subject = "good" AND Status = "open"'
    },
);

my $from = RT::Extension::MoveRules::Test->load_or_create_queue(
    Name => 'From'
);
my $to = RT::Extension::MoveRules::Test->load_or_create_queue(
    Name => 'To'
);

my $ticket;
{
    $ticket = RT::Ticket->new($RT::SystemUser);
    my ($tid, $msg) = $ticket->Create( Queue => $from->id, Subject => 'bad' );
    ok( $tid, "created ticket" );
}

{
    my ($status, $msg) = $ticket->SetQueue( $to->id );
    ok !$status, "didn't move ticket: $msg";
}

{
    my ($status, $msg) = $ticket->SetSubject("good");
    ok $status, "changed subject";
}

{
    my ($status, $msg) = $ticket->SetQueue( $to->id );
    ok !$status, "didn't move ticket: $msg";
}

{
    my ($status, $msg) = $ticket->SetStatus("open");
    ok $status, "changed status";
}

{
    my ($status, $msg) = $ticket->SetQueue( $to->id );
    ok $status, "moved ticket" or diag "error: $msg";
}

