package SignalWire::Skills::Builtin::NativeVectorSearch;
use strict;
use warnings;
use Moo;
extends 'SignalWire::Skills::SkillBase';

use SignalWire::Skills::SkillRegistry;
SignalWire::Skills::SkillRegistry->register_skill('native_vector_search', __PACKAGE__);

has '+skill_name'        => (default => sub { 'native_vector_search' });
has '+skill_description' => (default => sub { 'Search document indexes using vector similarity and keyword search (local or remote)' });
has '+supports_multiple_instances' => (default => sub { 1 });

sub setup { 1 }

sub register_tools {
    my ($self) = @_;
    my $tool_name   = $self->params->{tool_name}   // 'search_knowledge';
    my $description = $self->params->{description}  // 'Search the local knowledge base for information';

    $self->define_tool(
        name        => $tool_name,
        description => $description,
        parameters  => {
            type       => 'object',
            properties => {
                query => { type => 'string',  description => 'The search query' },
                count => { type => 'integer', description => 'Number of results', default => 3 },
            },
            required => ['query'],
        },
        handler => sub {
            my ($args, $raw) = @_;
            require SignalWire::SWAIG::FunctionResult;
            return SignalWire::SWAIG::FunctionResult->new(
                response => "Vector search for: $args->{query}"
            );
        },
    );
}

sub get_hints {
    my ($self) = @_;
    my @base = ('search', 'find', 'look up', 'documentation', 'knowledge base');
    push @base, @{ $self->params->{hints} // [] };
    return \@base;
}

sub _get_prompt_sections {
    return [{
        title   => 'Knowledge Search',
        body    => 'You have access to a document search capability.',
        bullets => ['Use the search tool to find relevant information'],
    }];
}

sub get_parameter_schema {
    return {
        %{ SignalWire::Skills::SkillBase->get_parameter_schema },
        remote_url  => { type => 'string' },
        index_name  => { type => 'string' },
        count       => { type => 'integer', default => 3 },
        description => { type => 'string' },
        hints       => { type => 'array' },
    };
}

1;
