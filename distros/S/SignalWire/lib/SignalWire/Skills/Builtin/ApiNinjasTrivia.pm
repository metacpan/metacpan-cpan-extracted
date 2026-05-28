package SignalWire::Skills::Builtin::ApiNinjasTrivia;
# Copyright (c) 2025 SignalWire
# Licensed under the MIT License.
#
# DataMap-based API Ninjas trivia skill. Mirrors signalwire-python's
# skills/api_ninjas_trivia/skill.py:get_tools — the SDK does NOT issue
# the HTTP request itself; the SignalWire SWML platform fetches the
# webhook URL described in the data_map, runs the response template,
# and returns the formatted result to the LLM. The SDK's job here is
# to register the right DataMap shape with the right URL/headers.

use strict;
use warnings;
use Moo;
use JSON ();
extends 'SignalWire::Skills::SkillBase';

use SignalWire::Skills::SkillRegistry;
SignalWire::Skills::SkillRegistry->register_skill('api_ninjas_trivia', __PACKAGE__);

has '+skill_name'        => (default => sub { 'api_ninjas_trivia' });
has '+skill_description' => (default => sub { 'Get trivia questions from API Ninjas' });
has '+supports_multiple_instances' => (default => sub { 1 });

my @ALL_CATEGORIES = qw(
    artliterature language sciencenature general fooddrink
    peopleplaces geography historyholidays entertainment
    toysgames music mathematics religionmythology
    sportsleisure
);

# Honor API_NINJAS_BASE_URL env var so the audit fixture
# (audit_skills_dispatch.py) can redirect us at a local HTTP server.
# When unset we use the canonical https://api.api-ninjas.com/v1/trivia
# URL Python writes verbatim. The audit's expected_path_substring is
# `trivia`, which is preserved either way.
sub _trivia_url {
    my $override = $ENV{API_NINJAS_BASE_URL};
    if ($override) {
        $override =~ s{/+$}{};
        return "$override/v1/trivia";
    }
    return 'https://api.api-ninjas.com/v1/trivia';
}

sub setup { 1 }

sub register_tools {
    my ($self) = @_;
    my $tool_name  = $self->params->{tool_name}  // 'get_trivia';
    my $api_key    = $self->params->{api_key}    // '';
    my $categories = $self->params->{categories} // [@ALL_CATEGORIES];

    require SignalWire::SWAIG::FunctionResult;

    my $no_results = SignalWire::SWAIG::FunctionResult->new(
        response => 'Sorry, I cannot get trivia questions right now. Please try again later.',
    )->to_hash;
    my $on_success = SignalWire::SWAIG::FunctionResult->new(
        response => 'Category %{array[0].category} question: %{array[0].question} '
                  . 'Answer: %{array[0].answer}, be sure to give the user time to answer '
                  . 'before saying the answer.',
    )->to_hash;

    my $url = _trivia_url();

    $self->agent->register_swaig_function({
        function    => $tool_name,
        description => "Get trivia questions for " . ($tool_name =~ s/_/ /gr),
        parameters  => {
            type       => 'object',
            properties => {
                category => {
                    type        => 'string',
                    description => 'Category for trivia question. Options: '
                                 . join('; ', @$categories),
                    enum => $categories,
                },
            },
            required => ['category'],
        },
        data_map => {
            webhooks => [{
                url     => "$url?category=%{args.category}",
                method  => 'GET',
                headers => { 'X-Api-Key' => $api_key },
                output  => $on_success,
            }],
            error_keys => ['error'],
            output     => $no_results,
        },
    });
}

sub get_parameter_schema {
    return {
        %{ SignalWire::Skills::SkillBase->get_parameter_schema },
        api_key    => { type => 'string', required => 1, hidden => 1 },
        categories => { type => 'array',  default => [@ALL_CATEGORIES] },
        tool_name  => { type => 'string', default => 'get_trivia' },
    };
}

1;
