package SignalWire::Prefabs::InfoGatherer;
# Copyright (c) 2025 SignalWire
# Licensed under the MIT License.

use strict;
use warnings;
use Moo;
use JSON qw(encode_json);
extends 'SignalWire::Agent::AgentBase';

has questions => (is => 'ro', default => sub { [] });

sub BUILD {
    my ($self, $args) = @_;

    # Set defaults
    $self->name('info_gatherer')  if $self->name eq 'agent';
    $self->route('/info_gatherer') if $self->route eq '/';
    $self->use_pom(1);

    my $questions = $self->questions;

    # Set global data
    $self->set_global_data({
        questions      => $questions,
        question_index => 0,
        answers        => [],
    });

    # Build prompt
    $self->prompt_add_section(
        'Information Gathering',
        'You are an information-gathering assistant. Your job is to ask the user a series of questions and collect their answers.',
        bullets => [
            'Ask questions one at a time in order',
            'Wait for the user to answer before asking the next question',
            'Confirm answers when the question requires confirmation',
            'Use start_questions to begin and submit_answer for each response',
        ],
    );

    # Register tools
    $self->define_tool(
        name        => 'start_questions',
        description => 'Start the question-gathering process and return the first question',
        parameters  => { type => 'object', properties => {} },
        handler     => sub {
            my ($a, $raw) = @_;
            require SignalWire::SWAIG::FunctionResult;
            my $first = $questions->[0]{question_text} // 'No questions configured';
            return SignalWire::SWAIG::FunctionResult->new(response => $first);
        },
    );

    $self->define_tool(
        name        => 'submit_answer',
        description => 'Submit an answer to the current question',
        parameters  => {
            type       => 'object',
            properties => {
                answer            => { type => 'string',  description => 'The answer' },
                confirmed_by_user => { type => 'boolean', description => 'User confirmed this answer' },
            },
            required => ['answer'],
        },
        handler => sub {
            my ($a, $raw) = @_;
            require SignalWire::SWAIG::FunctionResult;
            return SignalWire::SWAIG::FunctionResult->new(
                response => "Answer recorded: $a->{answer}",
            );
        },
    );
}

1;
