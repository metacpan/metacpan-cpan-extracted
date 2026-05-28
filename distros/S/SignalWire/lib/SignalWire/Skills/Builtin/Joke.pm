package SignalWire::Skills::Builtin::Joke;
use strict;
use warnings;
use Moo;
use JSON ();
extends 'SignalWire::Skills::SkillBase';

use SignalWire::Skills::SkillRegistry;
SignalWire::Skills::SkillRegistry->register_skill('joke', __PACKAGE__);

has '+skill_name'        => (default => sub { 'joke' });
has '+skill_description' => (default => sub { 'Tell jokes using the API Ninjas joke API' });
has '+supports_multiple_instances' => (default => sub { 0 });

sub setup { 1 }

sub register_tools {
    my ($self) = @_;
    my $tool_name = $self->params->{tool_name} // 'get_joke';

    # DataMap-style registration
    $self->agent->register_swaig_function({
        function    => $tool_name,
        description => 'Get a random joke from API Ninjas',
        parameters  => {
            type       => 'object',
            properties => {
                type => {
                    type        => 'string',
                    description => 'Type of joke',
                    enum        => ['jokes', 'dadjokes'],
                },
            },
            required => ['type'],
        },
        data_map => {
            webhooks => [{
                method  => 'GET',
                url     => 'https://api.api-ninjas.com/v1/${args.type}',
                headers => { 'X-Api-Key' => $self->params->{api_key} // '' },
                output  => {
                    response => 'Here\'s a joke: ${array[0].joke}',
                },
            }],
        },
    });
}

sub get_global_data {
    return { joke_skill_enabled => JSON::true };
}

sub _get_prompt_sections {
    return [{
        title   => 'Joke Telling',
        body    => 'You can tell jokes to lighten the mood.',
        bullets => [
            'Use the joke tool when the user asks for a joke',
            'Choose between regular jokes and dad jokes',
        ],
    }];
}

sub get_parameter_schema {
    return {
        %{ SignalWire::Skills::SkillBase->get_parameter_schema },
        api_key   => { type => 'string', required => 1, hidden => 1 },
        tool_name => { type => 'string', default => 'get_joke' },
    };
}

1;
