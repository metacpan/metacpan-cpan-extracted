#!/usr/bin/env perl

use strict;
use warnings;

use RT::Extension::MoveRules::Test tests => 11;

RT->Config->Set(
    'MoveRules' =>
    { },
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
    my ($tid, $msg) = $ticket->Create( Queue => $from->id, Subject => 'test' );
    ok( $tid, "created ticket" );
}

{
    my ($status, $msg) = $ticket->SetQueue( $to->id );
    ok !$status, "failed to move: $msg";
}

