package SignalWire::Prefabs::FAQBot;
# Copyright (c) 2025 SignalWire
# Licensed under the MIT License.

use strict;
use warnings;
use Moo;
use JSON qw(encode_json);
extends 'SignalWire::Agent::AgentBase';

has faqs            => (is => 'ro', default => sub { [] });
has suggest_related => (is => 'ro', default => sub { 1 });
has persona         => (is => 'ro', default => sub { 'You are a helpful FAQ bot that provides accurate answers to common questions.' });

sub BUILD {
    my ($self, $args) = @_;

    $self->name('faq_bot') if $self->name eq 'agent';
    $self->route('/faq')   if $self->route eq '/';
    $self->use_pom(1);

    my $faqs = $self->faqs;

    $self->set_global_data({
        faqs           => $faqs,
        suggest_related => $self->suggest_related ? JSON::true : JSON::false,
    });

    $self->prompt_add_section(
        'Personality',
        $self->persona,
    );

    # Build FAQ knowledge
    my @faq_bullets;
    for my $faq (@$faqs) {
        push @faq_bullets, "Q: $faq->{question} A: $faq->{answer}";
    }

    $self->prompt_add_section(
        'FAQ Knowledge Base',
        'You have knowledge of the following frequently asked questions.',
        bullets => \@faq_bullets,
    );

    if ($self->suggest_related) {
        $self->prompt_add_section(
            'Related Questions',
            'When appropriate, suggest related questions the user might also be interested in.',
        );
    }

    # Register lookup tool
    $self->define_tool(
        name        => 'lookup_faq',
        description => 'Look up an FAQ answer by keyword matching',
        parameters  => {
            type       => 'object',
            properties => {
                query => { type => 'string', description => 'The question or keywords to search' },
            },
            required => ['query'],
        },
        handler => sub {
            my ($a, $raw) = @_;
            require SignalWire::SWAIG::FunctionResult;
            my $query = lc($a->{query} // '');
            for my $faq (@$faqs) {
                if (index(lc($faq->{question}), $query) >= 0) {
                    return SignalWire::SWAIG::FunctionResult->new(
                        response => $faq->{answer},
                    );
                }
            }
            return SignalWire::SWAIG::FunctionResult->new(
                response => "No FAQ found matching: $a->{query}",
            );
        },
    );
}

1;
