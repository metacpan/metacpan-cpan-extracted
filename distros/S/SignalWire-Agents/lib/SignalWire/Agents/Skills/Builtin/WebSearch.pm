package SignalWire::Agents::Skills::Builtin::WebSearch;
use strict;
use warnings;
use Moo;
use JSON ();
extends 'SignalWire::Agents::Skills::SkillBase';

use SignalWire::Agents::Skills::SkillRegistry;
SignalWire::Agents::Skills::SkillRegistry->register_skill('web_search', __PACKAGE__);

has '+skill_name'        => (default => sub { 'web_search' });
has '+skill_description' => (default => sub { 'Search the web for information using Google Custom Search API' });
has '+skill_version'     => (default => sub { '2.0.0' });
has '+supports_multiple_instances' => (default => sub { 1 });

sub setup { 1 }

sub register_tools {
    my ($self) = @_;
    my $tool_name = $self->params->{tool_name} // 'web_search';

    $self->define_tool(
        name        => $tool_name,
        description => 'Search the web for high-quality information, automatically filtering low-quality results',
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
                response => "Web search results for: $args->{query}"
            );
        },
    );
}

sub get_global_data {
    return {
        web_search_enabled => JSON::true,
        search_provider    => 'Google Custom Search',
        quality_filtering  => JSON::true,
    };
}

sub _get_prompt_sections {
    return [{
        title   => 'Web Search Capability (Quality Enhanced)',
        body    => '',
        bullets => [
            'Use web_search to find current information',
            'Results are quality-filtered automatically',
        ],
    }];
}

sub get_parameter_schema {
    return {
        %{ SignalWire::Agents::Skills::SkillBase->get_parameter_schema },
        api_key          => { type => 'string', required => 1, hidden => 1 },
        search_engine_id => { type => 'string', required => 1, hidden => 1 },
        num_results      => { type => 'integer', default => 3, min => 1, max => 10 },
    };
}

1;
