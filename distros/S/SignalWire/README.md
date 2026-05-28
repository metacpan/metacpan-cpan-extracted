<!-- Header -->
<div align="center">
    <a href="https://signalwire.com" target="_blank">
        <img src="https://github.com/user-attachments/assets/0c8ed3b9-8c50-4dc6-9cc4-cc6cd137fd50" width="500" />
    </a>

# SignalWire SDK for Perl

_Build AI voice agents, control live calls over WebSocket, and manage every SignalWire resource over REST -- all from one package._

<p align="center">
  <a href="https://developer.signalwire.com/sdks/agents-sdk" target="_blank">Documentation</a> &middot;
  <a href="https://github.com/signalwire/signalwire-docs/issues/new/choose" target="_blank">Report an Issue</a> &middot;
  <a href="https://metacpan.org/pod/SignalWire" target="_blank">CPAN</a>
</p>

<a href="https://discord.com/invite/F2WNYTNjuF" target="_blank"><img src="https://img.shields.io/badge/Discord%20Community-5865F2" alt="Discord" /></a>
<a href="LICENSE"><img src="https://img.shields.io/badge/MIT-License-blue" alt="MIT License" /></a>
<a href="https://github.com/signalwire/signalwire-perl" target="_blank"><img src="https://img.shields.io/github/stars/signalwire/signalwire-perl" alt="GitHub Stars" /></a>

<a href="https://codespaces.new/signalwire/signalwire-perl" target="_blank"><img src="https://github.com/codespaces/badge.svg" alt="Open in GitHub Codespaces" /></a>
<a href="https://replit.com/new/github/signalwire/signalwire-perl" target="_blank"><img src="https://replit.com/badge/github/signalwire/signalwire-perl" alt="Run on Replit" /></a>

</div>

---

## What's in this SDK

| Capability | What it does | Quick link |
|-----------|-------------|------------|
| **AI Agents** | Build voice agents that handle calls autonomously -- the platform runs the AI pipeline, your code defines the persona, tools, and call flow | [Agent Guide](#ai-agents) |
| **RELAY Client** | Control live calls and SMS/MMS in real time over WebSocket -- answer, play, record, collect DTMF, conference, transfer, and more | [RELAY docs](relay/README.md) |
| **REST Client** | Manage SignalWire resources over HTTP -- phone numbers, SIP endpoints, Fabric AI agents, video rooms, messaging, and 18+ API namespaces | [REST docs](rest/README.md) |

```bash
cpanm SignalWire
```

---

## AI Agents

Each agent is a self-contained microservice that generates [SWML](docs/swml_service_guide.md) (SignalWire Markup Language) and handles [SWAIG](docs/swaig_reference.md) (SignalWire AI Gateway) tool calls. The SignalWire platform runs the entire AI pipeline (STT, LLM, TTS) -- your agent just defines the behavior.

```perl
use strict;
use warnings;
use SignalWire;
use SignalWire::Agent::AgentBase;
use SignalWire::SWAIG::FunctionResult;
use POSIX qw(strftime);

my $agent = SignalWire::Agent::AgentBase->new(
    name  => 'my-agent',
    route => '/agent',
);

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->prompt_add_section('Role', 'You are a helpful assistant.');

$agent->define_tool(
    name        => 'get_time',
    description => 'Get the current time',
    parameters  => {},
    handler     => sub {
        my ($args, $raw_data) = @_;
        return SignalWire::SWAIG::FunctionResult->new(
            response => 'The time is ' . strftime('%H:%M:%S', localtime),
        );
    },
);

$agent->run;
```

Test locally without running a server:

```bash
swaig-test my_agent.pl --list-tools
swaig-test my_agent.pl --dump-swml
swaig-test my_agent.pl --exec get_time
```

### Agent Features

- **Prompt Object Model (POM)** -- structured prompt composition via `prompt_add_section()`
- **SWAIG tools** -- define functions with `define_tool()` that the AI calls mid-conversation, with native access to the call's media stack
- **Skills system** -- add capabilities with one-liners: `$agent->add_skill('datetime')`
- **Contexts and steps** -- structured multi-step workflows with navigation control
- **DataMap tools** -- tools that execute on SignalWire's servers, calling REST APIs without your own webhook
- **Dynamic configuration** -- per-request agent customization for multi-tenant deployments
- **Call flow control** -- pre-answer, post-answer, and post-AI verb insertion
- **Prefab agents** -- ready-to-use archetypes (InfoGatherer, Survey, FAQ, Receptionist, Concierge)
- **Multi-agent hosting** -- serve multiple agents on a single server with `SignalWire::Agent::AgentServer`
- **SIP routing** -- route SIP calls to agents based on usernames
- **Session state** -- persistent conversation state with global data and post-prompt summaries
- **Security** -- auto-generated basic auth, function-specific HMAC tokens, SSL support
- **Serverless** -- auto-detects Lambda, CGI, Google Cloud Functions, Azure Functions
- **PSGI/Plack** -- run standalone or mount in any PSGI-compatible framework

### Agent Examples

The [`examples/`](examples/) directory contains 39 working examples:

| Example | What it demonstrates |
|---------|---------------------|
| [simple_agent.pl](examples/simple_agent.pl) | POM prompts, SWAIG tools, multilingual support, LLM tuning |
| [contexts_demo.pl](examples/contexts_demo.pl) | Multi-persona workflow with context switching and step navigation |
| [datamap_demo.pl](examples/datamap_demo.pl) | Server-side API tools without webhooks |
| [skills_demo.pl](examples/skills_demo.pl) | Loading built-in skills (datetime, math) |
| [call_flow.pl](examples/call_flow.pl) | Call flow verbs, debug events, FunctionResult actions |
| [session_state.pl](examples/session_state.pl) | on_summary, global data, post-prompt summaries |
| [multi_agent_server.pl](examples/multi_agent_server.pl) | Multiple agents on one server |
| [lambda_agent.pl](examples/lambda_agent.pl) | AWS Lambda deployment |
| [comprehensive_dynamic.pl](examples/comprehensive_dynamic.pl) | Per-request dynamic configuration, multi-tenant routing |

See [examples/README.md](examples/README.md) for the full list organized by category.

---

## RELAY Client

Real-time call control and messaging over WebSocket. The RELAY client connects to SignalWire via the Blade protocol and gives you imperative control over live phone calls and SMS/MMS.

```perl
use strict;
use warnings;
use SignalWire::Relay::Client;

my $client = SignalWire::Relay::Client->new(
    project  => $ENV{SIGNALWIRE_PROJECT_ID},
    token    => $ENV{SIGNALWIRE_API_TOKEN},
    host     => $ENV{SIGNALWIRE_SPACE} // 'relay.signalwire.com',
    contexts => ['default'],
);

$client->on_call(sub {
    my ($call) = @_;
    $call->answer;
    my $action = $call->play(
        media => [{ type => 'tts', params => { text => 'Welcome!' } }],
    );
    $action->wait;
    $call->hangup;
});

$client->run;
```

- 57+ calling methods (play, record, collect, detect, tap, stream, AI, conferencing, and more)
- SMS/MMS messaging with delivery tracking
- Action objects with `wait()`, `stop()`, `pause()`, `resume()`
- Auto-reconnect with exponential backoff

See the **[RELAY documentation](relay/README.md)** for the full guide, API reference, and examples.

---

## REST Client

Synchronous REST client for managing SignalWire resources and controlling calls over HTTP. No WebSocket required.

```perl
use strict;
use warnings;
use SignalWire::REST::RestClient;

my $client = SignalWire::REST::RestClient->new(
    project => $ENV{SIGNALWIRE_PROJECT_ID},
    token   => $ENV{SIGNALWIRE_API_TOKEN},
    host    => $ENV{SIGNALWIRE_SPACE},
);

$client->fabric->ai_agents->create(name => 'Support Bot', prompt => { text => 'You are helpful.' });
$client->calling->play($call_id, play => [{ type => 'tts', text => 'Hello!' }]);
$client->phone_numbers->search(area_code => '512');
$client->datasphere->documents->search(query_string => 'billing policy');
```

- 21 namespaced API surfaces: Fabric (13 resource types), Calling (37 commands), Video, Datasphere, Compat (Twilio-compatible), Phone Numbers, SIP, Queues, Recordings, and more
- HTTP::Tiny for lightweight, dependency-free HTTP
- Hash ref returns -- raw data, no wrapper objects

See the **[REST documentation](rest/README.md)** for the full guide, API reference, and examples.

---

## Installation

```bash
# From CPAN
cpanm SignalWire

# From source
cpanm --installdeps .
perl Makefile.PL
make test
make install
```

## Documentation

Full reference documentation is available at **[developer.signalwire.com/sdks/agents-sdk](https://developer.signalwire.com/sdks/agents-sdk)**.

Guides are also available in the [`docs/`](docs/) directory:

### Getting Started

- [Agent Guide](docs/agent_guide.md) -- creating agents, prompt configuration, dynamic setup
- [Architecture](docs/architecture.md) -- SDK architecture and core concepts
- [SDK Features](docs/sdk_features.md) -- feature overview, SDK vs raw SWML comparison

### Core Features

- [SWAIG Reference](docs/swaig_reference.md) -- function results, actions, post_data lifecycle
- [Contexts and Steps](docs/contexts_guide.md) -- structured workflows, navigation, gather mode
- [DataMap Guide](docs/datamap_guide.md) -- serverless API tools without webhooks
- [LLM Parameters](docs/llm_parameters.md) -- temperature, top_p, barge confidence tuning
- [SWML Service Guide](docs/swml_service_guide.md) -- low-level construction of SWML documents

### Skills and Extensions

- [Skills System](docs/skills_system.md) -- built-in skills and the modular framework
- [Third-Party Skills](docs/third_party_skills.md) -- creating and publishing custom skills
- [MCP Gateway](docs/mcp_gateway_reference.md) -- Model Context Protocol integration

### Deployment

- [CLI Guide](docs/cli_guide.md) -- `swaig-test` command reference
- [Cloud Functions](docs/cloud_functions_guide.md) -- Lambda, Cloud Functions, Azure deployment
- [Configuration](docs/configuration.md) -- environment variables, SSL, proxy setup
- [Security](docs/security.md) -- authentication and security model

### Reference

- [API Reference](docs/api_reference.md) -- complete class and method reference
- [Web Service](docs/web_service.md) -- HTTP server and endpoint details
- [Skills Parameter Schema](docs/skills_parameter_schema.md) -- skill parameter definitions

## Environment Variables

| Variable | Used by | Description |
|----------|---------|-------------|
| `SIGNALWIRE_PROJECT_ID` | RELAY, REST | Project identifier |
| `SIGNALWIRE_API_TOKEN` | RELAY, REST | API token |
| `SIGNALWIRE_SPACE` | RELAY, REST | Space hostname (e.g. `example.signalwire.com`) |
| `SWML_BASIC_AUTH_USER` | Agents | Basic auth username (default: auto-generated) |
| `SWML_BASIC_AUTH_PASSWORD` | Agents | Basic auth password (default: auto-generated) |
| `SWML_PROXY_URL_BASE` | Agents | Base URL when behind a reverse proxy |
| `SWML_SSL_ENABLED` | Agents | Enable HTTPS (`true`, `1`, `yes`) |
| `SWML_SSL_CERT_PATH` | Agents | Path to SSL certificate |
| `SWML_SSL_KEY_PATH` | Agents | Path to SSL private key |
| `SIGNALWIRE_LOG_LEVEL` | All | Logging level (`debug`, `info`, `warn`, `error`) |
| `SIGNALWIRE_LOG_MODE` | All | Set to `off` to suppress all logging |

## Testing

```bash
# Install dependencies
cpanm --installdeps .

# Run the full test suite
prove -lv t/

# Run a single test
prove -lv t/06_agent.t

# Coverage
cover -test -report html
```

## License

MIT -- see [LICENSE](LICENSE) for details.
