package SignalWire::Prefabs::Survey;
# Copyright (c) 2025 SignalWire
# Licensed under the MIT License.

use strict;
use warnings;
use Moo;
use JSON qw(encode_json);
extends 'SignalWire::Agent::AgentBase';

has survey_name   => (is => 'ro', default => sub { 'Survey' });
has survey_questions => (is => 'ro', default => sub { [] });
has introduction  => (is => 'ro', default => sub { '' });
has conclusion    => (is => 'ro', default => sub { '' });
has brand_name    => (is => 'ro', default => sub { '' });
has max_retries   => (is => 'ro', default => sub { 2 });

sub BUILD {
    my ($self, $args) = @_;

    $self->name('survey')  if $self->name eq 'agent';
    $self->route('/survey') if $self->route eq '/';
    $self->use_pom(1);

    my $questions = $self->survey_questions;

    $self->set_global_data({
        survey_name    => $self->survey_name,
        questions      => $questions,
        question_index => 0,
        answers        => {},
        completed      => JSON::false,
    });

    my $intro = $self->introduction || "Welcome to the ${\$self->survey_name}.";
    $self->prompt_add_section(
        'Survey Introduction',
        $intro,
        bullets => [
            'Introduce the survey to the user',
            'Ask each question in sequence',
            'Validate responses based on question type',
            'Thank the user when complete',
        ],
    );

    # Build question descriptions
    my @q_bullets;
    for my $q (@$questions) {
        my $desc = "Q: $q->{text} (type: $q->{type})";
        $desc .= " [required]" if $q->{required};
        push @q_bullets, $desc;
    }
    $self->prompt_add_section('Survey Questions', '', bullets => \@q_bullets);

    # Register survey tools
    $self->define_tool(
        name        => 'submit_survey_answer',
        description => 'Submit an answer for the current survey question',
        parameters  => {
            type       => 'object',
            properties => {
                question_id => { type => 'string',  description => 'ID of the question' },
                answer      => { type => 'string',  description => 'The answer' },
            },
            required => ['question_id', 'answer'],
        },
        handler => sub {
            my ($a, $raw) = @_;
            require SignalWire::SWAIG::FunctionResult;
            return SignalWire::SWAIG::FunctionResult->new(
                response => "Survey answer for $a->{question_id}: $a->{answer}",
            );
        },
    );
}

1;
