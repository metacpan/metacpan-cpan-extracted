package SignalWire::Agents::Skills::Builtin::Datasphere;
use strict;
use warnings;
use Moo;
use JSON ();
extends 'SignalWire::Agents::Skills::SkillBase';

use SignalWire::Agents::Skills::SkillRegistry;
SignalWire::Agents::Skills::SkillRegistry->register_skill('datasphere', __PACKAGE__);

has '+skill_name'        => (default => sub { 'datasphere' });
has '+skill_description' => (default => sub { 'Search knowledge using SignalWire DataSphere RAG stack' });
has '+supports_multiple_instances' => (default => sub { 1 });

sub setup { 1 }

sub register_tools {
    my ($self) = @_;
    my $tool_name = $self->params->{tool_name} // 'search_knowledge';

    $self->define_tool(
        name        => $tool_name,
        description => 'Search the knowledge base for information on any topic and return relevant results',
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
                response => "DataSphere search for: $args->{query}"
            );
        },
    );
}

sub get_hints { return [] }

sub get_global_data {
    my ($self) = @_;
    return {
        datasphere_enabled   => JSON::true,
        document_id          => $self->params->{document_id} // '',
        knowledge_provider   => 'SignalWire DataSphere',
    };
}

sub _get_prompt_sections {
    return [{
        title   => 'Knowledge Search Capability',
        body    => 'You have access to a knowledge base that you can search for information.',
        bullets => [
            'Use the search tool to find relevant information',
            'Provide accurate answers based on search results',
        ],
    }];
}

sub get_parameter_schema {
    return {
        %{ SignalWire::Agents::Skills::SkillBase->get_parameter_schema },
        space_name  => { type => 'string', required => 1 },
        project_id  => { type => 'string', required => 1 },
        token       => { type => 'string', required => 1 },
        document_id => { type => 'string', required => 1 },
        count       => { type => 'integer', default => 1, min => 1, max => 10 },
        distance    => { type => 'number', default => 3.0 },
    };
}

1;
