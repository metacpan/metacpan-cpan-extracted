package SignalWire::Agents::Skills::Builtin::WikipediaSearch;
use strict;
use warnings;
use Moo;
extends 'SignalWire::Agents::Skills::SkillBase';

use SignalWire::Agents::Skills::SkillRegistry;
SignalWire::Agents::Skills::SkillRegistry->register_skill('wikipedia_search', __PACKAGE__);

has '+skill_name'        => (default => sub { 'wikipedia_search' });
has '+skill_description' => (default => sub { 'Search Wikipedia for information about a topic and get article summaries' });
has '+supports_multiple_instances' => (default => sub { 0 });

sub setup { 1 }

sub register_tools {
    my ($self) = @_;

    $self->define_tool(
        name        => 'search_wiki',
        description => 'Search Wikipedia for information about a topic and get article summaries',
        parameters  => {
            type       => 'object',
            properties => {
                query => { type => 'string', description => 'The search query' },
            },
            required => ['query'],
        },
        handler => sub {
            my ($args, $raw) = @_;
            require SignalWire::Agents::SWAIG::FunctionResult;
            return SignalWire::Agents::SWAIG::FunctionResult->new(
                response => "Wikipedia search for: $args->{query}"
            );
        },
    );
}

sub _get_prompt_sections {
    return [{
        title   => 'Wikipedia Search',
        body    => 'You can search Wikipedia for factual information.',
        bullets => [
            'Use search_wiki to find information about any topic',
            'Results include article summaries from Wikipedia',
        ],
    }];
}

sub get_parameter_schema {
    return {
        %{ SignalWire::Agents::Skills::SkillBase->get_parameter_schema },
        num_results        => { type => 'integer', default => 1, min => 1, max => 5 },
        no_results_message => { type => 'string' },
    };
}

1;
