#!/usr/bin/env perl

use strict;
use warnings;

use RT::Extension::MoveRules::Test tests => 16;

RT->Config->Set(
    'MoveRules' =>
    {
        From => 'From', To => 'To',
        Rule => 'Subject = "good" AND Status = "open"',
        ShowAction => 1,
    },
);

my $from = RT::Extension::MoveRules::Test->load_or_create_queue(
    Name => 'From'
);
my $to = RT::Extension::MoveRules::Test->load_or_create_queue(
    Name => 'To'
);

my ($baseurl, $agent) = RT::Test->started_ok;
ok( $agent->login, 'logged in' );

my $ticket;
{
    $ticket = RT::Ticket->new($RT::SystemUser);
    my ($tid, $msg) = $ticket->Create(
        Queue => $from->id,
        Subject => 'good',
    );
    ok( $tid, "created ticket" );
}

{
    $agent->goto_ticket( $ticket->id );
    ok( !$agent->follow_link(text => 'to To'), "no action link" );
}

{
    my ($status, $msg) = $ticket->SetStatus('open');
    ok( $status, "changed status" ) or diag "error: $msg";
}

{
    $agent->goto_ticket( $ticket->id );
    $agent->follow_link_ok({ text => 'to To' }, "jumped to edit" );
}

{
    DBIx::SearchBuilder::Record::Cachable->FlushCache;
    my $tmp = RT::Ticket->new($RT::SystemUser);
    $tmp->Load( $ticket->id );
    is( $tmp->QueueObj->id, $to->id, "changed queue" );
}

