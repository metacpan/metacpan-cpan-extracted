package SignalWire::Agents::Relay::Event;
use strict;
use warnings;
use Moo;

# Base event class -- all relay events inherit from this.
has 'event_type' => ( is => 'ro', default => sub { '' } );
has 'timestamp'  => ( is => 'ro', default => sub { 0 } );
has 'params'     => ( is => 'ro', default => sub { {} } );

# --- Subclasses for each event type ---

# Call state change: created, ringing, answered, ending, ended
package SignalWire::Agents::Relay::Event::CallState;
use Moo;
extends 'SignalWire::Agents::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'tag'        => ( is => 'ro', default => sub { '' } );
has 'call_state' => ( is => 'ro', default => sub { '' } );
has 'device'     => ( is => 'ro', default => sub { {} } );
has 'end_reason' => ( is => 'ro', default => sub { '' } );
has 'peer'       => ( is => 'ro', default => sub { {} } );

# Inbound call offer
package SignalWire::Agents::Relay::Event::CallReceive;
use Moo;
extends 'SignalWire::Agents::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'tag'        => ( is => 'ro', default => sub { '' } );
has 'call_state' => ( is => 'ro', default => sub { '' } );
has 'device'     => ( is => 'ro', default => sub { {} } );
has 'context'    => ( is => 'ro', default => sub { '' } );

# Dial completion
package SignalWire::Agents::Relay::Event::CallDial;
use Moo;
extends 'SignalWire::Agents::Relay::Event';
has 'tag'        => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'dial_state' => ( is => 'ro', default => sub { '' } );
has 'call'       => ( is => 'ro', default => sub { {} } );

# Connect state
package SignalWire::Agents::Relay::Event::CallConnect;
use Moo;
extends 'SignalWire::Agents::Relay::Event';
has 'call_id'       => ( is => 'ro', default => sub { '' } );
has 'node_id'       => ( is => 'ro', default => sub { '' } );
has 'connect_state' => ( is => 'ro', default => sub { '' } );
has 'peer'          => ( is => 'ro', default => sub { {} } );

# Disconnect state
package SignalWire::Agents::Relay::Event::CallDisconnect;
use Moo;
extends 'SignalWire::Agents::Relay::Event';
has 'call_id' => ( is => 'ro', default => sub { '' } );
has 'node_id' => ( is => 'ro', default => sub { '' } );

# Play state
package SignalWire::Agents::Relay::Event::CallPlay;
use Moo;
extends 'SignalWire::Agents::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'control_id' => ( is => 'ro', default => sub { '' } );
has 'state'      => ( is => 'ro', default => sub { '' } );

# Record state
package SignalWire::Agents::Relay::Event::CallRecord;
use Moo;
extends 'SignalWire::Agents::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'control_id' => ( is => 'ro', default => sub { '' } );
has 'state'      => ( is => 'ro', default => sub { '' } );
has 'url'        => ( is => 'ro', default => sub { '' } );
has 'duration'   => ( is => 'ro', default => sub { 0 } );
has 'size'       => ( is => 'ro', default => sub { 0 } );
has 'record'     => ( is => 'ro', default => sub { {} } );

# Collect result
package SignalWire::Agents::Relay::Event::CallCollect;
use Moo;
extends 'SignalWire::Agents::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'control_id' => ( is => 'ro', default => sub { '' } );
has 'result'     => ( is => 'ro', default => sub { {} } );

# Detect result
package SignalWire::Agents::Relay::Event::CallDetect;
use Moo;
extends 'SignalWire::Agents::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'control_id' => ( is => 'ro', default => sub { '' } );
has 'detect'     => ( is => 'ro', default => sub { {} } );

# Fax state (send_fax / receive_fax)
package SignalWire::Agents::Relay::Event::CallFax;
use Moo;
extends 'SignalWire::Agents::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'control_id' => ( is => 'ro', default => sub { '' } );
has 'fax'        => ( is => 'ro', default => sub { {} } );

# Tap state
package SignalWire::Agents::Relay::Event::CallTap;
use Moo;
extends 'SignalWire::Agents::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'control_id' => ( is => 'ro', default => sub { '' } );
has 'state'      => ( is => 'ro', default => sub { '' } );
has 'tap'        => ( is => 'ro', default => sub { {} } );

# Stream state
package SignalWire::Agents::Relay::Event::CallStream;
use Moo;
extends 'SignalWire::Agents::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'control_id' => ( is => 'ro', default => sub { '' } );
has 'state'      => ( is => 'ro', default => sub { '' } );

# Transcribe state
package SignalWire::Agents::Relay::Event::CallTranscribe;
use Moo;
extends 'SignalWire::Agents::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'control_id' => ( is => 'ro', default => sub { '' } );
has 'state'      => ( is => 'ro', default => sub { '' } );

# Pay state
package SignalWire::Agents::Relay::Event::CallPay;
use Moo;
extends 'SignalWire::Agents::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'control_id' => ( is => 'ro', default => sub { '' } );
has 'state'      => ( is => 'ro', default => sub { '' } );
has 'result'     => ( is => 'ro', default => sub { {} } );

# Send digits event
package SignalWire::Agents::Relay::Event::CallSendDigits;
use Moo;
extends 'SignalWire::Agents::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'control_id' => ( is => 'ro', default => sub { '' } );
has 'state'      => ( is => 'ro', default => sub { '' } );

# SIP REFER event
package SignalWire::Agents::Relay::Event::CallRefer;
use Moo;
extends 'SignalWire::Agents::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'refer_state' => ( is => 'ro', default => sub { '' } );

# Conference event
package SignalWire::Agents::Relay::Event::Conference;
use Moo;
extends 'SignalWire::Agents::Relay::Event';
has 'call_id'       => ( is => 'ro', default => sub { '' } );
has 'node_id'       => ( is => 'ro', default => sub { '' } );
has 'conference_id' => ( is => 'ro', default => sub { '' } );

# AI event
package SignalWire::Agents::Relay::Event::CallAI;
use Moo;
extends 'SignalWire::Agents::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'control_id' => ( is => 'ro', default => sub { '' } );

# Inbound message
package SignalWire::Agents::Relay::Event::MessageReceive;
use Moo;
extends 'SignalWire::Agents::Relay::Event';
has 'message_id'    => ( is => 'ro', default => sub { '' } );
has 'context'       => ( is => 'ro', default => sub { '' } );
has 'direction'     => ( is => 'ro', default => sub { 'inbound' } );
has 'from_number'   => ( is => 'ro', default => sub { '' } );
has 'to_number'     => ( is => 'ro', default => sub { '' } );
has 'body'          => ( is => 'ro', default => sub { '' } );
has 'media'         => ( is => 'ro', default => sub { [] } );
has 'segments'      => ( is => 'ro', default => sub { 0 } );
has 'message_state' => ( is => 'ro', default => sub { 'received' } );
has 'tags'          => ( is => 'ro', default => sub { [] } );

# Outbound message state change
package SignalWire::Agents::Relay::Event::MessageState;
use Moo;
extends 'SignalWire::Agents::Relay::Event';
has 'message_id'    => ( is => 'ro', default => sub { '' } );
has 'context'       => ( is => 'ro', default => sub { '' } );
has 'direction'     => ( is => 'ro', default => sub { 'outbound' } );
has 'from_number'   => ( is => 'ro', default => sub { '' } );
has 'to_number'     => ( is => 'ro', default => sub { '' } );
has 'body'          => ( is => 'ro', default => sub { '' } );
has 'media'         => ( is => 'ro', default => sub { [] } );
has 'segments'      => ( is => 'ro', default => sub { 0 } );
has 'message_state' => ( is => 'ro', default => sub { '' } );
has 'reason'        => ( is => 'ro', default => sub { '' } );
has 'tags'          => ( is => 'ro', default => sub { [] } );

# Authorization state
package SignalWire::Agents::Relay::Event::AuthorizationState;
use Moo;
extends 'SignalWire::Agents::Relay::Event';
has 'authorization_state' => ( is => 'ro', default => sub { '' } );

# Server disconnect
package SignalWire::Agents::Relay::Event::Disconnect;
use Moo;
extends 'SignalWire::Agents::Relay::Event';
has 'restart' => ( is => 'ro', default => sub { 0 } );

# --- Factory method ---
package SignalWire::Agents::Relay::Event;

# Map event_type string to class name
my %EVENT_CLASS_MAP = (
    'calling.call.state'             => 'SignalWire::Agents::Relay::Event::CallState',
    'calling.call.receive'           => 'SignalWire::Agents::Relay::Event::CallReceive',
    'calling.call.dial'              => 'SignalWire::Agents::Relay::Event::CallDial',
    'calling.call.connect'           => 'SignalWire::Agents::Relay::Event::CallConnect',
    'calling.call.disconnect'        => 'SignalWire::Agents::Relay::Event::CallDisconnect',
    'calling.call.play'              => 'SignalWire::Agents::Relay::Event::CallPlay',
    'calling.call.record'            => 'SignalWire::Agents::Relay::Event::CallRecord',
    'calling.call.collect'           => 'SignalWire::Agents::Relay::Event::CallCollect',
    'calling.call.detect'            => 'SignalWire::Agents::Relay::Event::CallDetect',
    'calling.call.fax'               => 'SignalWire::Agents::Relay::Event::CallFax',
    'calling.call.tap'               => 'SignalWire::Agents::Relay::Event::CallTap',
    'calling.call.stream'            => 'SignalWire::Agents::Relay::Event::CallStream',
    'calling.call.transcribe'        => 'SignalWire::Agents::Relay::Event::CallTranscribe',
    'calling.call.pay'               => 'SignalWire::Agents::Relay::Event::CallPay',
    'calling.call.send_digits'       => 'SignalWire::Agents::Relay::Event::CallSendDigits',
    'calling.call.refer'             => 'SignalWire::Agents::Relay::Event::CallRefer',
    'calling.conference'             => 'SignalWire::Agents::Relay::Event::Conference',
    'calling.call.ai'                => 'SignalWire::Agents::Relay::Event::CallAI',
    'messaging.receive'              => 'SignalWire::Agents::Relay::Event::MessageReceive',
    'messaging.state'                => 'SignalWire::Agents::Relay::Event::MessageState',
    'signalwire.authorization.state' => 'SignalWire::Agents::Relay::Event::AuthorizationState',
    'signalwire.disconnect'          => 'SignalWire::Agents::Relay::Event::Disconnect',
);

sub parse_event {
    my ($class_or_self, $event_type, $params) = @_;
    $params //= {};

    my $event_class = $EVENT_CLASS_MAP{$event_type};
    unless ($event_class) {
        # Return base event for unknown types
        return SignalWire::Agents::Relay::Event->new(
            event_type => $event_type,
            params     => $params,
        );
    }

    # Build constructor args from event params
    my %args = (
        event_type => $event_type,
        params     => $params,
    );

    # Copy known fields from params into top-level attributes
    for my $key (keys %$params) {
        # Moo will silently ignore unknown attrs, so we just pass everything
        $args{$key} = $params->{$key};
    }

    return $event_class->new(%args);
}

1;
