package RT::Action::AddTicketSummary;

use RT;
use strict;
use warnings;
use base qw(RT::Action);

use Encode;
use JSON;

sub Prepare {
    return 1;
}

sub Commit {
    my $self      = shift;
    my $ticket    = $self->TicketObj;
    my $ticket_id = $ticket->id;

    my $transactions = $ticket->Transactions;

    $transactions->Limit( FIELD => 'Type', OPERATION => '=', VALUE => 'Correspond' );

    my $conversation = '';
    my $max_chars    = 3000;

    while ( my $txn = $transactions->Next ) {
        my $content = $txn->Content;
        next unless $content;

        # TODO: identify privileged vs. unprivileged users
        # TODO: make $max_chars configurable

        $conversation .= "User: " . $txn->CreatorObj->Name . " ";
        $conversation .= "Reply: " . $content . "\n";

        last if length($conversation) > $max_chars;
    }

    unless ($conversation) {
        RT->Logger->info("No content to summarize for ticket #$ticket_id.");
        return 1;
    }

    my $queue = $self->TicketObj->QueueObj->Name;
    my $config = RT->Config->Get('RT_AI_Provider');
    $config = $config->{$queue} || $config->{Default};

    return 1 unless $config;

    my $provider_class = "RT::Extension::AI::Provider::" . $config->{name};
    my $provider = $provider_class->new(config => $config);

    my $response = $provider->process_request(
        prompt       => $config->{prompts}{summarize_ticket},
        raw_text     => $conversation,
        model_config => $config->{default_model},
    );

    unless ( $response->{success} ) {
        RT->Logger->info(
            "Summary generation failed for ticket #$ticket_id: $response->{error}"
        );
        return 1;
    }

    my $summary = $response->{result};
    RT->Logger->info("Generated summary for ticket #$ticket_id: $summary");

    $ticket->AddCustomFieldValue(
        Field => 'Ticket Summary',
        Value => $summary,
    );

    return 1;
}

RT::Base->_ImportOverlays();

1;
