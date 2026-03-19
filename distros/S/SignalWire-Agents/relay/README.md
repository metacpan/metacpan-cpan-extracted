# SignalWire RELAY Client (Perl)

Real-time call control and messaging over WebSocket. The RELAY client connects to SignalWire via the Blade protocol (JSON-RPC 2.0 over WebSocket) and gives you imperative control over live phone calls and SMS/MMS messaging.

## Quick Start

```perl
use lib 'lib';
use SignalWire::Agents::Relay::Client;

my $client = SignalWire::Agents::Relay::Client->new(
    project  => $ENV{SIGNALWIRE_PROJECT_ID},
    token    => $ENV{SIGNALWIRE_API_TOKEN},
    host     => $ENV{SIGNALWIRE_SPACE} // 'relay.signalwire.com',
    contexts => ['default'],
);

$client->on_call(sub {
    my ($call) = @_;
    print "Incoming call: ${\$call->call_id}\n";
    $call->answer;
    my $action = $call->play(media => [
        { type => 'tts', params => { text => 'Welcome to SignalWire!' } },
    ]);
    $action->wait;
    $call->hangup;
});

$client->connect_ws;
$client->authenticate;
print "Waiting for inbound calls on context 'default' ...\n";
$client->run;
```

## Features

- Synchronous blocking API (no async/await required)
- Auto-reconnect with exponential backoff
- All calling methods: play, record, collect, connect, detect, fax, tap, stream, AI, conferencing, queues, and more
- SMS/MMS messaging: send outbound messages, receive inbound messages, track delivery state
- Action objects with `wait()`, `stop()`, `pause()`, `resume()` for controllable operations
- Typed event classes for all call events
- Dynamic context subscription/unsubscription

## Documentation

- [Getting Started](docs/getting-started.md) -- installation, configuration, first call
- [Call Methods Reference](docs/call-methods.md) -- every method available on a Call object
- [Events](docs/events.md) -- event types, typed event classes, call states
- [Messaging](docs/messaging.md) -- sending and receiving SMS/MMS messages
- [Client Reference](docs/client-reference.md) -- RelayClient configuration, methods, connection behavior

## Examples

| File | Description |
|------|-------------|
| [relay_answer_and_welcome.pl](examples/relay_answer_and_welcome.pl) | Answer an inbound call and play a TTS greeting |
| [relay_dial_and_play.pl](examples/relay_dial_and_play.pl) | Dial an outbound number, wait for answer, and play TTS |
| [relay_ivr_connect.pl](examples/relay_ivr_connect.pl) | IVR menu with DTMF collection, playback, and call connect |

## Environment Variables

| Variable | Description |
|----------|-------------|
| `SIGNALWIRE_PROJECT_ID` | Project ID for authentication |
| `SIGNALWIRE_API_TOKEN` | API token for authentication |
| `SIGNALWIRE_SPACE` | Space hostname (default: `relay.signalwire.com`) |
| `SIGNALWIRE_LOG_LEVEL` | Log level (`debug` for WebSocket traffic) |

## Module Structure

```
lib/SignalWire/Agents/Relay/
    Client.pm       # RelayClient -- WebSocket connection, auth, event dispatch
    Call.pm         # Call object -- all calling methods
    Action.pm       # Action classes for controllable operations
    Event.pm        # Typed event classes
    Message.pm      # SMS/MMS message tracking
    Constants.pm    # Protocol constants, call states, event types
```
