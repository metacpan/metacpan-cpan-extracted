package SignalWire::Skills::Builtin::McpGateway;
use strict;
use warnings;
use Moo;
extends 'SignalWire::Skills::SkillBase';

use SignalWire::Skills::SkillRegistry;
SignalWire::Skills::SkillRegistry->register_skill('mcp_gateway', __PACKAGE__);

has '+skill_name'        => (default => sub { 'mcp_gateway' });
has '+skill_description' => (default => sub { 'Bridge MCP servers with SWAIG functions' });
has '+supports_multiple_instances' => (default => sub { 0 });

sub setup { 1 }

sub register_tools {
    my ($self) = @_;
    my $prefix   = $self->params->{tool_prefix} // 'mcp_';
    my $services = $self->params->{services} // [];

    # Register a stub tool for each service
    for my $svc (@$services) {
        my $svc_name = ref $svc eq 'HASH' ? ($svc->{name} // 'default') : $svc;
        my $tool_name = "${prefix}${svc_name}";
        $self->define_tool(
            name        => $tool_name,
            description => "[$svc_name] MCP gateway tool",
            parameters  => {
                type       => 'object',
                properties => {
                    arguments => { type => 'string', description => 'Arguments to pass to MCP service' },
                },
            },
            handler => sub {
                my ($args, $raw) = @_;
                require SignalWire::SWAIG::FunctionResult;
                return SignalWire::SWAIG::FunctionResult->new(
                    response => "MCP gateway call to $svc_name"
                );
            },
        );
    }
}

sub get_hints {
    my ($self) = @_;
    my @hints = ('MCP', 'gateway');
    for my $svc (@{ $self->params->{services} // [] }) {
        push @hints, ref $svc eq 'HASH' ? ($svc->{name} // ()) : $svc;
    }
    return \@hints;
}

sub get_global_data {
    my ($self) = @_;
    return {
        mcp_gateway_url => $self->params->{gateway_url} // '',
        mcp_session_id  => undef,
        mcp_services    => $self->params->{services} // [],
    };
}

sub _get_prompt_sections {
    return [{
        title   => 'MCP Gateway Integration',
        body    => 'You have access to MCP gateway services.',
        bullets => ['Use MCP tools to interact with connected services'],
    }];
}

sub get_parameter_schema {
    return {
        %{ SignalWire::Skills::SkillBase->get_parameter_schema },
        gateway_url   => { type => 'string', required => 1 },
        auth_token    => { type => 'string', hidden => 1 },
        services      => { type => 'array' },
        tool_prefix   => { type => 'string', default => 'mcp_' },
    };
}

1;
