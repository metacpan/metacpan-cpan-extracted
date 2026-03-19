# SignalWire AI Agents Perl SDK

A Perl framework for building, deploying, and managing AI agents as microservices that interact with the [SignalWire](https://signalwire.com) platform.

## Features

- **Agent Framework** — Build AI agents with structured prompts, tools, and skills
- **SWML Generation** — Automatic SWML document creation for the SignalWire AI platform
- **SWAIG Functions** — Define tools the AI can call during conversations
- **DataMap Tools** — Server-side API integrations without webhook infrastructure
- **Contexts & Steps** — Structured multi-step conversation workflows
- **Skills System** — Modular, reusable capabilities (datetime, math, web search, etc.)
- **Prefab Agents** — Ready-to-use agent patterns (surveys, reception, FAQ, etc.)
- **Multi-Agent Hosting** — Run multiple agents on a single server
- **RELAY Client** — Real-time WebSocket-based call control and messaging
- **REST Client** — Full SignalWire REST API access
- **PSGI/Plack** — Run standalone or mount in any PSGI-compatible framework

## Quick Start

```perl
use SignalWire::Agents;

my $agent = SignalWire::Agents::AgentBase->new(name => 'my-agent');

$agent->set_prompt_text("You are a helpful assistant.");

$agent->define_tool(
    name        => 'get_time',
    description => 'Get the current time',
    parameters  => {},
    handler     => sub {
        my ($args, $raw_data) = @_;
        return SignalWire::Agents::FunctionResult->new(
            response => "The current time is " . localtime()
        );
    },
);

$agent->run;
```

## Installation

```bash
# From CPAN
cpanm SignalWire::Agents

# From source
cpanm --installdeps .
perl Makefile.PL
make test
make install
```

## PSGI / Plack Integration

```perl
# app.psgi
use SignalWire::Agents;

my $agent = SignalWire::Agents::AgentBase->new(name => 'my-agent');
$agent->set_prompt_text("You are a helpful assistant.");

$agent->psgi_app;
```

```bash
plackup app.psgi
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | HTTP server port | `3000` |
| `SWML_BASIC_AUTH_USER` | Basic auth username | auto-generated |
| `SWML_BASIC_AUTH_PASSWORD` | Basic auth password | auto-generated |
| `SWML_PROXY_URL_BASE` | Proxy/tunnel base URL | auto-detected |
| `SIGNALWIRE_PROJECT_ID` | Project ID for RELAY/REST | — |
| `SIGNALWIRE_API_TOKEN` | API token for RELAY/REST | — |
| `SIGNALWIRE_SPACE` | Space hostname | — |

## License

Copyright (c) SignalWire. All rights reserved.
