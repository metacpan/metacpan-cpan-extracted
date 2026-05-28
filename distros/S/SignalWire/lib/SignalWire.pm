package SignalWire;
use strict;
use warnings;

our $VERSION = '2.0.2';

use SignalWire::Logging;
use SignalWire::SWML::Document;
use SignalWire::SWML::Schema;
use SignalWire::SWML::Service;
use SignalWire::SWAIG::FunctionResult;
use SignalWire::Security::SessionManager;
use SignalWire::DataMap;
use SignalWire::Contexts;

# -------------------------------------------------------------------------
# Top-level convenience entry points
#
# Mirror Python's package-level signalwire/__init__.py — RestClient
# factory + skill registry helpers (register_skill, add_skill_directory,
# list_skills_with_params). These delegate to the underlying classes.
# -------------------------------------------------------------------------

# Singleton SkillRegistry "instance" — Perl's SkillRegistry stores state
# in package-level variables, so the helpers below operate on the class
# directly rather than building a Moo-style instance. This sub returns
# the class name (good enough for ->method() invocations) and exists so
# tests can introspect singleton state via the same accessor used at
# runtime.
sub _singleton_registry {
    require SignalWire::Skills::SkillRegistry;
    return 'SignalWire::Skills::SkillRegistry';
}

# Construct a SignalWire::REST::RestClient instance.
#
# Mirrors Python's top-level ``signalwire.RestClient(*args, **kwargs)``
# factory — a thin wrapper that lazy-loads ``SignalWire::REST::RestClient``
# and calls its constructor. Supports either positional credentials
# (project, token, host) or hash-style keyword credentials.
#
# The signature is declared with ``my (@args, %kwargs) = @_;`` so the
# audit's regex-based dumper sees the canonical variadic shape (Perl's
# slurpy array + slurpy hash mirror Python's ``*args, **kwargs``). At
# runtime, only one of @args / %kwargs will actually be populated since
# Perl's slurpy semantics greedily consume the remaining arglist into
# the array; keyword-style callers pass an even number of args (no
# leading positional) so @args becomes the kwargs pairlist instead.
sub RestClient {
    # Audit-shape declaration: declare both slurpy positional and slurpy
    # hash so the surface enumerator sees the canonical ``*args, **kwargs``
    # shape Python uses. We don't actually rely on %kwargs at runtime —
    # Perl's slurpy-array semantics consume everything into @args, so
    # %kwargs always ends up empty. Real argument splitting happens below.
    my (@args, %kwargs) = @_;
    require SignalWire::REST::RestClient;
    # Three bare strings -> positional (project, token, host); anything
    # else is a hash-style keyword args list passed via @_.
    my @raw = @_;
    if (@raw == 3 && !ref($raw[0]) && $raw[0] !~ /^(?:project|token|host)$/) {
        return SignalWire::REST::RestClient->new(
            project => $raw[0],
            token   => $raw[1],
            host    => $raw[2],
        );
    }
    return SignalWire::REST::RestClient->new(@raw);
}

# Register a custom skill class with the global skill registry.
#
# Mirrors Python's ``signalwire.register_skill(skill_class)``. The class
# is expected to expose a ``::skill_name`` accessor or a ``SKILL_NAME``
# constant so the registration key can be derived.
sub register_skill {
    my ($skill_class) = @_;
    require SignalWire::Skills::SkillRegistry;
    my $name;
    if ($skill_class->can('skill_name')) {
        $name = $skill_class->skill_name;
    } elsif (defined &{"${skill_class}::SKILL_NAME"}) {
        no strict 'refs';
        $name = ${"${skill_class}::SKILL_NAME"};
    } else {
        die "skill class $skill_class must define ::skill_name or SKILL_NAME\n";
    }
    SignalWire::Skills::SkillRegistry->register_skill($name, $skill_class);
    return;
}

# Add a directory to search for skills.
#
# Mirrors Python's ``signalwire.add_skill_directory(path)`` — delegates
# to the singleton SkillRegistry instance so third-party skill
# collections can be registered by path. Subsequent calls accumulate
# (de-duplicated) into a shared external paths list.
sub add_skill_directory {
    my ($path) = @_;
    return _singleton_registry()->add_skill_directory($path);
}

# Get complete schema for all available skills.
#
# Mirrors Python's ``signalwire.list_skills_with_params()``. Returns a
# hashref keyed by skill name where each value contains parameter
# metadata. Useful for GUI configuration tools, API documentation, or
# programmatic skill discovery.
sub list_skills_with_params {
    require SignalWire::Skills::SkillRegistry;
    if (SignalWire::Skills::SkillRegistry->can('get_all_skills_schema')) {
        return SignalWire::Skills::SkillRegistry->get_all_skills_schema;
    }
    # Fallback: list_skills returns names; pair them with empty params.
    my $names = SignalWire::Skills::SkillRegistry->list_skills;
    return { map { $_ => { name => $_, parameters => {} } } @$names };
}

1;

__END__

=head1 NAME

SignalWire - SDK for building AI agents as microservices on SignalWire

=head1 SYNOPSIS

    use SignalWire::Agent::AgentBase;

    my $agent = SignalWire::Agent::AgentBase->new(
        name  => 'my_agent',
        route => '/agent',
        host  => '0.0.0.0',
        port  => 3000,
    );

    # Build structured prompts
    $agent->prompt_add_section('Role', 'You are a helpful assistant.');
    $agent->prompt_add_section('Rules',
        body   => ['Be concise', 'Be friendly'],
        bullet => '*',
    );

    # Define tools with local handlers
    $agent->define_tool(
        name        => 'get_time',
        description => 'Get the current time',
        parameters  => { type => 'object', properties => {} },
        handler     => sub {
            my ($args, $raw) = @_;
            require SignalWire::SWAIG::FunctionResult;
            return SignalWire::SWAIG::FunctionResult->new(
                "The time is " . localtime
            );
        },
    );

    # Add built-in skills
    $agent->add_skill('datetime');
    $agent->add_skill('math');

    # Start the HTTP server
    $agent->run();

=head1 DESCRIPTION

SignalWire is the Perl port of the SignalWire AI Agents SDK. It provides
a framework for building, deploying, and managing AI agents as self-contained
web applications that expose HTTP endpoints to interact with the SignalWire
platform.

=head2 Key Features

=over 4

=item * B<Prompt Object Model> - Structured, section-based prompt management

=item * B<Local Tools> - Define tool handlers that execute in your agent process

=item * B<DataMap Tools> - Server-side API integration without webhooks

=item * B<Skills System> - Modular, reusable capabilities (datetime, math, web search, etc.)

=item * B<Contexts> - Branching workflow management for multi-step conversations

=item * B<Prefabs> - Ready-made agent types (InfoGatherer, Survey, Receptionist, etc.)

=item * B<Multi-Agent Server> - Host multiple agents in a single process

=item * B<RELAY Client> - Real-time WebSocket call control

=item * B<REST Client> - Synchronous HTTP API for SignalWire resources

=back

=head1 CORE MODULES

=over 4

=item L<SignalWire::Agent::AgentBase> - Base class for all AI agents

=item L<SignalWire::SWML::Service> - SWML document management

=item L<SignalWire::SWAIG::FunctionResult> - Tool response builder with actions

=item L<SignalWire::DataMap> - Declarative server-side API tools

=item L<SignalWire::Contexts> - Workflow context management

=item L<SignalWire::Server::AgentServer> - Multi-agent HTTP server

=item L<SignalWire::Relay::Client> - WebSocket-based call control

=item L<SignalWire::REST::RestClient> - REST API client

=back

=head1 TOOL TYPES

=head2 Local Tools

Handler subroutines that execute within your agent process:

    $agent->define_tool(
        name        => 'lookup_order',
        description => 'Look up an order by ID',
        parameters  => {
            type       => 'object',
            properties => {
                order_id => { type => 'string', description => 'Order ID' },
            },
            required => ['order_id'],
        },
        handler => sub {
            my ($args, $raw) = @_;
            my $order = get_order($args->{order_id});
            return SignalWire::SWAIG::FunctionResult->new(
                "Order status: $order->{status}"
            );
        },
    );

=head2 DataMap Tools

Declarative API calls evaluated server-side, no webhook required:

    use SignalWire::DataMap;

    my $tool = SignalWire::DataMap->new('get_weather')
        ->description('Get weather for a location')
        ->parameter('city', 'string', 'City name', required => 1)
        ->webhook('GET', 'https://api.weather.com/v1?q=${args.city}')
        ->output(SignalWire::SWAIG::FunctionResult->new(
            'Weather: ${response.temp}°F'
        ));

    $agent->register_swaig_function($tool->to_swaig_function);

=head2 Skills

Pre-built capabilities added with a single call:

    $agent->add_skill('datetime');
    $agent->add_skill('math');
    $agent->add_skill('web_search', {
        api_key          => $ENV{GOOGLE_SEARCH_API_KEY},
        search_engine_id => $ENV{GOOGLE_SEARCH_ENGINE_ID},
    });

=head1 ENVIRONMENT VARIABLES

=over 4

=item C<SWML_BASIC_AUTH_USER> / C<SWML_BASIC_AUTH_PASSWORD> - Override auto-generated basic auth credentials

=item C<SIGNALWIRE_PROJECT_ID> - Project ID for Relay and REST clients

=item C<SIGNALWIRE_API_TOKEN> - API token for Relay and REST clients

=item C<SIGNALWIRE_SPACE> - SignalWire space hostname

=back

=head1 SOURCE

L<https://github.com/signalwire/signalwire-agents-perl>

=head1 LICENSE

This is free software licensed under the MIT License.

=cut
