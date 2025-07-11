package RT::Action::AddTicketSentiment;

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

    # Build ticket content
    my $transactions = $ticket->Transactions;
    my $conversation = '';
    my $max_chars    = 3000;

    while ( my $txn = $transactions->Next ) {
        my $content = $txn->Content;
        next unless $content;
        $conversation .= $content . "\n";
        last if length($conversation) > $max_chars;
    }

    unless ($conversation) {
        RT->Logger->info("No content to analyze for ticket #$ticket_id.");
        return 1;
    }

    my $queue = $self->TicketObj->QueueObj->Name;
    my $config = RT->Config->Get('RT_AI_Provider');
    $config = $config->{$queue} || $config->{Default};

    return 1 unless $config;

    my $provider_class = "RT::Extension::AI::Provider::" . $config->{name};
    my $provider = $provider_class->new(config => $config);

    my $response = $provider->process_request(
        prompt       => $config->{prompts}{assess_sentiment},
        raw_text     => $conversation,
        model_config => $config->{default_model},
    );

    unless ( $response->{success} ) {
        RT->Logger->error(
            "Sentiment analysis failed for ticket #$ticket_id: $response->{error}"
        );
        return 1;
    }

    my $sentiment = $response->{result} || 'Neutral';

    # Normalize the result
    my %sentiment_map = (
        qr/satisfied/i    => 'Satisfied',
        qr/dissatisfied/i => 'Dissatisfied',
        qr/neutral/i      => 'Neutral',
    );

    my $normalized = 'Neutral';
    for my $regex ( keys %sentiment_map ) {
        if ( $sentiment =~ $regex ) {
            $normalized = $sentiment_map{$regex};
            last;
        }
    }

    RT->Logger->info("Ticket #$ticket_id sentiment: $normalized");

    $ticket->AddCustomFieldValue(
        Field => 'Ticket Sentiment',
        Value => $normalized,
    );

    return 1;
}

RT::Base->_ImportOverlays();

1;
