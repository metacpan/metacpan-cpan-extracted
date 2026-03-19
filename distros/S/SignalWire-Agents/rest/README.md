# SignalWire REST Client (Perl)

Synchronous REST client for managing SignalWire resources, controlling live calls, and interacting with every SignalWire API surface from Perl. No WebSocket required -- just standard HTTP requests via HTTP::Tiny.

## Quick Start

```perl
use lib 'lib';
use SignalWire::Agents::REST::SignalWireClient;

my $client = SignalWire::Agents::REST::SignalWireClient->new(
    project => $ENV{SIGNALWIRE_PROJECT_ID},
    token   => $ENV{SIGNALWIRE_API_TOKEN},
    host    => $ENV{SIGNALWIRE_SPACE},
);

# Create an AI agent
my $agent = $client->fabric->ai_agents->create(
    name   => 'Support Bot',
    prompt => { text => 'You are a helpful support agent.' },
);

# Search for a phone number
my $results = $client->phone_numbers->search(area_code => '512');

# Place a call via REST
$client->calling->dial(
    from_ => '+15559876543',
    to    => '+15551234567',
    url   => 'https://example.com/call-handler',
);
```

## Features

- Single `SignalWireClient` with namespaced sub-objects for every API
- All calling commands: dial, play, record, collect, detect, tap, stream, AI, transcribe, and more
- Full Fabric API: resource types with CRUD + addresses, tokens, and generic resources
- Datasphere: document management and semantic search
- Video: rooms, sessions, recordings, conferences, tokens, streams
- Compatibility API: full Twilio-compatible LAML surface
- Phone number management, 10DLC registry, MFA, logs, and more
- HTTP::Tiny for lightweight, dependency-free HTTP
- Hash ref returns -- raw data, no wrapper objects to learn

## Documentation

- [Getting Started](docs/getting-started.md) -- installation, configuration, first API call
- [Client Reference](docs/client-reference.md) -- SignalWireClient constructor, namespaces, error handling
- [Fabric Resources](docs/fabric.md) -- managing AI agents, SWML scripts, subscribers, call flows, and more
- [Calling Commands](docs/calling.md) -- REST-based call control (dial, play, record, collect, AI, etc.)
- [Compatibility API](docs/compat.md) -- Twilio-compatible LAML endpoints
- [All Namespaces](docs/namespaces.md) -- phone numbers, video, datasphere, logs, registry, and more

## Examples

| File | Description |
|------|-------------|
| [rest_10dlc_registration.pl](examples/rest_10dlc_registration.pl) | 10DLC brand and campaign compliance registration |
| [rest_calling_ivr_and_ai.pl](examples/rest_calling_ivr_and_ai.pl) | IVR input, AI operations, live transcription, tap, stream |
| [rest_calling_play_and_record.pl](examples/rest_calling_play_and_record.pl) | Media operations: play, record, transcribe, denoise |
| [rest_compat_laml.pl](examples/rest_compat_laml.pl) | Twilio-compatible LAML migration |
| [rest_datasphere_search.pl](examples/rest_datasphere_search.pl) | Upload document, run semantic search |
| [rest_fabric_conferences_and_routing.pl](examples/rest_fabric_conferences_and_routing.pl) | Conferences, cXML resources, generic routing, tokens |
| [rest_fabric_subscribers_and_sip.pl](examples/rest_fabric_subscribers_and_sip.pl) | Provision SIP-enabled users on Fabric |
| [rest_fabric_swml_and_callflows.pl](examples/rest_fabric_swml_and_callflows.pl) | SWML scripts and call flows |
| [rest_manage_resources.pl](examples/rest_manage_resources.pl) | Create AI agent, assign number, place test call |
| [rest_phone_number_management.pl](examples/rest_phone_number_management.pl) | Full phone number inventory lifecycle |
| [rest_queues_mfa_and_recordings.pl](examples/rest_queues_mfa_and_recordings.pl) | Call queues, recording review, MFA verification |
| [rest_video_rooms.pl](examples/rest_video_rooms.pl) | Video rooms, sessions, conferences, streams |

## Environment Variables

| Variable | Description |
|----------|-------------|
| `SIGNALWIRE_PROJECT_ID` | Project ID for authentication |
| `SIGNALWIRE_API_TOKEN` | API token for authentication |
| `SIGNALWIRE_SPACE` | Space hostname (e.g. `example.signalwire.com`) |
| `SIGNALWIRE_LOG_LEVEL` | Log level (`debug` for HTTP request details) |

## Module Structure

```
lib/SignalWire/Agents/REST/
    SignalWireClient.pm    # Main client -- namespace wiring, lazy builders
    HttpClient.pm          # HTTP::Tiny wrapper with auth, JSON, error handling
    Namespaces/
        Fabric.pm          # AI agents, SWML scripts, subscribers, call flows, etc.
        Calling.pm         # REST-based call control commands
        PhoneNumbers.pm    # Search, purchase, update, release
        Compat.pm          # Twilio-compatible LAML API
        Video.pm           # Rooms, sessions, recordings, conferences
        Datasphere.pm      # Documents, search, chunks
        Registry.pm        # 10DLC brands, campaigns, orders
        ... and more
```
