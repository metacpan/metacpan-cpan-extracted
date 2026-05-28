#!/usr/bin/env perl
# swmlservice_ai_sidecar.pl
#
# Proves that SignalWire::SWML::Service can emit the `ai_sidecar` verb,
# register SWAIG tools the sidecar's LLM can call, and dispatch them
# end-to-end - without any AgentBase code path.
#
# The `ai_sidecar` verb runs an AI listener alongside an in-progress
# call (real-time copilot, transcription analyzer, compliance monitor,
# etc.). It is NOT an agent - it does not own the call. So the right
# host is SWML::Service, not AgentBase.
#
# Run:
#     perl -Ilib examples/swmlservice_ai_sidecar.pl
#
# What this serves:
#     GET  /sales-sidecar         -> SWML doc with the ai_sidecar verb
#     POST /sales-sidecar/swaig   -> SWAIG tool dispatch (used by the
#                                    sidecar's LLM)
#
# Drive the SWAIG path through the bundled CLI:
#     bin/swaig-test --url http://user:pass@localhost:3000/sales-sidecar --list-tools
#     bin/swaig-test --url http://user:pass@localhost:3000/sales-sidecar \
#         --exec lookup_competitor --param competitor=ACME

use strict;
use warnings;
use lib 'lib';
use SignalWire::SWML::Service;

sub build_service {
    my %opts = @_;
    my $public_url = $opts{public_url}
        // 'https://your-host.example.com/sales-sidecar';

    my %args = (
        name                => 'sales-sidecar',
        route               => '/sales-sidecar',
        basic_auth_user     => $opts{user} // 'user',
        basic_auth_password => $opts{pass} // 'pass',
    );
    # Only override host/port when caller provides one - otherwise the
    # Service constructor honors SWML_HOST / SWML_PORT environment vars.
    $args{host} = $opts{host} if defined $opts{host};
    $args{port} = $opts{port} if defined $opts{port};
    my $svc = SignalWire::SWML::Service->new(%args);

    # 1. Emit any SWML - including ai_sidecar. The Document API's
    #    add_verb() accepts arbitrary verb dicts, so new platform verbs
    #    work without an SDK release. NOTE the SWAIG hash key MUST be
    #    UPPERCASE - that is how mod_openai recognizes it.
    $svc->document->add_verb('main', 'answer', {});
    $svc->document->add_verb('main', 'ai_sidecar', {
        prompt => 'You are a real-time sales copilot. Listen to the call '
                . 'and surface competitor pricing comparisons when relevant.',
        lang      => 'en-US',
        direction => ['remote-caller', 'local-caller'],
        # Where the sidecar POSTs lifecycle / transcription events.
        # Optional - skip if you don't need an event sink.
        url   => "$public_url/events",
        # Where the sidecar's LLM POSTs SWAIG tool calls. This SDK's
        # /swaig route is what answers them.
        SWAIG => {
            defaults => { web_hook_url => "$public_url/swaig" },
        },
    });
    $svc->document->add_verb('main', 'hangup', {});

    # 2. Register tools the sidecar's LLM can call. Same define_tool()
    #    you'd use on AgentBase - it lives on SWML::Service.
    $svc->define_tool(
        name        => 'lookup_competitor',
        description => 'Look up competitor pricing by company name. The sidecar '
                     . 'should call this whenever the caller mentions a competitor.',
        parameters  => {
            type       => 'object',
            properties => {
                competitor => {
                    type        => 'string',
                    description => "The competitor's company name, e.g. 'ACME'.",
                },
            },
            required   => ['competitor'],
        },
        handler => sub {
            my ($args, $raw_data) = @_;
            my $competitor = $args->{competitor} // '<unknown>';
            return {
                response => "Pricing for $competitor: \$99/seat. Our equivalent "
                          . 'plan is $79/seat with the same SLA.',
            };
        },
    );

    # 3. (Optional) Register a routing callback for ai_sidecar lifecycle
    #    events. The Service stores the callback under its routing
    #    table; it is invoked by handlers that override
    #    handle_additional_route() in subclasses. Comment this out if
    #    you don't need it.
    $svc->register_routing_callback('/events', sub {
        my ($request_data, $env) = @_;
        my $event_type = $request_data->{type} // '<unknown>';
        warn "[sidecar event] type=$event_type\n";
        return { ok => 1 };
    });

    return $svc;
}

# Top-level: only run the server when executed directly.
unless (caller) {
    my $svc = build_service();
    print "SWML::Service ai_sidecar host\n";
    print "Route:      " . $svc->route . "\n";
    print "Basic auth: " . $svc->basic_auth_user . ":" . $svc->basic_auth_password . "\n";
    print "SWML URL:   http://"
        . $svc->basic_auth_user . ":" . $svc->basic_auth_password
        . "\@" . $svc->host . ":" . $svc->port . $svc->route . "\n\n";

    require Plack::Runner;
    my $runner = Plack::Runner->new;
    $runner->parse_options(
        '--host'   => $svc->host,
        '--port'   => $svc->port,
        '--server' => 'HTTP::Server::PSGI',
    );
    $runner->run($svc->to_psgi_app);
}

1;
