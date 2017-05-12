#!/usr/bin/env perl

use strict;
use warnings;

use RT::Extension::MoveRules::Test tests => 23;

RT->Config->Set(
    'MoveRules' =>
    {
        From => 'From', To => 'To',
        Rule => 'Subject = "good" AND Status = "open"'
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
    $agent->follow_link_ok({ text => 'Basics' }, "jumped to edit" )
        or diag $agent->content;

    my $form = $agent->form_number(3);
    my $input = $form->find_input( 'Queue' );
    ok( $input, 'found queue selector' );
    is( scalar $input->possible_values, 1, 'one option' );
    is( ($input->possible_values)[0], $from->id, 'option is correct' );
}

{
    my ($status, $msg) = $ticket->SetStatus('open');
    ok( $status, "changed status" ) or diag "error: $msg";
}

{
    $agent->goto_ticket( $ticket->id );
    $agent->follow_link_ok({ text => 'Basics' }, "jumped to edit" )
        or diag $agent->content;

    my $form = $agent->form_number(3);
    my $input = $form->find_input( 'Queue' );
    ok( $input, 'found queue selector' );
    is( scalar $input->possible_values, 2, 'one option' );
    is( ($input->possible_values)[0], $from->id, 'option is correct' );
    is( ($input->possible_values)[1], $to->id, 'option is correct' );

    $agent->select(Queue => $to->id);
    $agent->submit;
}

{
    DBIx::SearchBuilder::Record::Cachable->FlushCache;
    my $tmp = RT::Ticket->new($RT::SystemUser);
    $tmp->Load( $ticket->id );
    is( $tmp->QueueObj->id, $to->id, "changed queue" );
}

