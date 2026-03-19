package SignalWire::Agents::Skills::Builtin::DatasphereServerless;
use strict;
use warnings;
use Moo;
use JSON ();
extends 'SignalWire::Agents::Skills::SkillBase';

use SignalWire::Agents::Skills::SkillRegistry;
SignalWire::Agents::Skills::SkillRegistry->register_skill('datasphere_serverless', __PACKAGE__);

has '+skill_name'        => (default => sub { 'datasphere_serverless' });
has '+skill_description' => (default => sub { 'Search knowledge using SignalWire DataSphere with serverless DataMap execution' });
has '+supports_multiple_instances' => (default => sub { 1 });

sub setup { 1 }

sub register_tools {
    my ($self) = @_;
    my $tool_name = $self->params->{tool_name} // 'search_knowledge';

    # DataMap-based tool: register as a SWAIG function definition
    $self->agent->register_swaig_function({
        function    => $tool_name,
        description => 'Search the knowledge base for information on any topic and return relevant results',
        parameters  => {
            type       => 'object',
            properties => {
                query => { type => 'string', description => 'The search query' },
            },
            required => ['query'],
        },
        data_map => {
            webhooks => [{
                method => 'POST',
                url    => 'https://' . ($self->params->{space_name} // '') . '/api/datasphere/documents/search',
                output => {
                    response => 'I found results for "${args.query}":\n\n${formatted_results}',
                    action   => [{ say => 'Here are the search results.' }],
                },
            }],
        },
    });
}

sub get_hints { return [] }

sub get_global_data {
    my ($self) = @_;
    return {
        datasphere_serverless_enabled => JSON::true,
        document_id                   => $self->params->{document_id} // '',
        knowledge_provider            => 'SignalWire DataSphere (Serverless)',
    };
}

sub _get_prompt_sections {
    return [{
        title   => 'Knowledge Search Capability (Serverless)',
        body    => 'You have access to a serverless knowledge base search.',
        bullets => [
            'Use the search tool to find relevant information',
            'Results are processed server-side for efficiency',
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
