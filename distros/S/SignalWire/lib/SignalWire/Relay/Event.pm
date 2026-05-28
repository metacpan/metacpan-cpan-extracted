package SignalWire::Relay::Event;
use strict;
use warnings;
use Moo;

# Base event class -- all relay events inherit from this.
has 'event_type' => ( is => 'ro', default => sub { '' } );
has 'timestamp'  => ( is => 'ro', default => sub { 0 } );
has 'params'     => ( is => 'ro', default => sub { {} } );

# --- Subclasses for each event type ---

# Call state change: created, ringing, answered, ending, ended
package SignalWire::Relay::Event::CallState;
use Moo;
extends 'SignalWire::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'tag'        => ( is => 'ro', default => sub { '' } );
has 'call_state' => ( is => 'ro', default => sub { '' } );
has 'device'     => ( is => 'ro', default => sub { {} } );
has 'end_reason' => ( is => 'ro', default => sub { '' } );
has 'peer'       => ( is => 'ro', default => sub { {} } );

# Inbound call offer
package SignalWire::Relay::Event::CallReceive;
use Moo;
extends 'SignalWire::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'tag'        => ( is => 'ro', default => sub { '' } );
has 'call_state' => ( is => 'ro', default => sub { '' } );
has 'device'     => ( is => 'ro', default => sub { {} } );
has 'context'    => ( is => 'ro', default => sub { '' } );

# Dial completion
package SignalWire::Relay::Event::CallDial;
use Moo;
extends 'SignalWire::Relay::Event';
has 'tag'        => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'dial_state' => ( is => 'ro', default => sub { '' } );
has 'call'       => ( is => 'ro', default => sub { {} } );

# Connect state
package SignalWire::Relay::Event::CallConnect;
use Moo;
extends 'SignalWire::Relay::Event';
has 'call_id'       => ( is => 'ro', default => sub { '' } );
has 'node_id'       => ( is => 'ro', default => sub { '' } );
has 'connect_state' => ( is => 'ro', default => sub { '' } );
has 'peer'          => ( is => 'ro', default => sub { {} } );

# Disconnect state
package SignalWire::Relay::Event::CallDisconnect;
use Moo;
extends 'SignalWire::Relay::Event';
has 'call_id' => ( is => 'ro', default => sub { '' } );
has 'node_id' => ( is => 'ro', default => sub { '' } );

# Play state
package SignalWire::Relay::Event::CallPlay;
use Moo;
extends 'SignalWire::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'control_id' => ( is => 'ro', default => sub { '' } );
has 'state'      => ( is => 'ro', default => sub { '' } );

# Record state
package SignalWire::Relay::Event::CallRecord;
use Moo;
extends 'SignalWire::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'control_id' => ( is => 'ro', default => sub { '' } );
has 'state'      => ( is => 'ro', default => sub { '' } );
has 'url'        => ( is => 'ro', default => sub { '' } );
has 'duration'   => ( is => 'ro', default => sub { 0 } );
has 'size'       => ( is => 'ro', default => sub { 0 } );
has 'record'     => ( is => 'ro', default => sub { {} } );

# Collect result
package SignalWire::Relay::Event::CallCollect;
use Moo;
extends 'SignalWire::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'control_id' => ( is => 'ro', default => sub { '' } );
has 'result'     => ( is => 'ro', default => sub { {} } );

# Detect result
package SignalWire::Relay::Event::CallDetect;
use Moo;
extends 'SignalWire::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'control_id' => ( is => 'ro', default => sub { '' } );
has 'detect'     => ( is => 'ro', default => sub { {} } );

# Fax state (send_fax / receive_fax)
package SignalWire::Relay::Event::CallFax;
use Moo;
extends 'SignalWire::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'control_id' => ( is => 'ro', default => sub { '' } );
has 'fax'        => ( is => 'ro', default => sub { {} } );

# Tap state
package SignalWire::Relay::Event::CallTap;
use Moo;
extends 'SignalWire::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'control_id' => ( is => 'ro', default => sub { '' } );
has 'state'      => ( is => 'ro', default => sub { '' } );
has 'tap'        => ( is => 'ro', default => sub { {} } );

# Stream state
package SignalWire::Relay::Event::CallStream;
use Moo;
extends 'SignalWire::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'control_id' => ( is => 'ro', default => sub { '' } );
has 'state'      => ( is => 'ro', default => sub { '' } );

# Transcribe state
package SignalWire::Relay::Event::CallTranscribe;
use Moo;
extends 'SignalWire::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'control_id' => ( is => 'ro', default => sub { '' } );
has 'state'      => ( is => 'ro', default => sub { '' } );

# Pay state
package SignalWire::Relay::Event::CallPay;
use Moo;
extends 'SignalWire::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'control_id' => ( is => 'ro', default => sub { '' } );
has 'state'      => ( is => 'ro', default => sub { '' } );
has 'result'     => ( is => 'ro', default => sub { {} } );

# Send digits event
package SignalWire::Relay::Event::CallSendDigits;
use Moo;
extends 'SignalWire::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'control_id' => ( is => 'ro', default => sub { '' } );
has 'state'      => ( is => 'ro', default => sub { '' } );

# SIP REFER event
package SignalWire::Relay::Event::CallRefer;
use Moo;
extends 'SignalWire::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'refer_state' => ( is => 'ro', default => sub { '' } );

# Conference event
package SignalWire::Relay::Event::Conference;
use Moo;
extends 'SignalWire::Relay::Event';
has 'call_id'       => ( is => 'ro', default => sub { '' } );
has 'node_id'       => ( is => 'ro', default => sub { '' } );
has 'conference_id' => ( is => 'ro', default => sub { '' } );

# AI event
package SignalWire::Relay::Event::CallAI;
use Moo;
extends 'SignalWire::Relay::Event';
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'control_id' => ( is => 'ro', default => sub { '' } );

# Inbound message
package SignalWire::Relay::Event::MessageReceive;
use Moo;
extends 'SignalWire::Relay::Event';
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
package SignalWire::Relay::Event::MessageState;
use Moo;
extends 'SignalWire::Relay::Event';
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
package SignalWire::Relay::Event::AuthorizationState;
use Moo;
extends 'SignalWire::Relay::Event';
has 'authorization_state' => ( is => 'ro', default => sub { '' } );

# Server disconnect
package SignalWire::Relay::Event::Disconnect;
use Moo;
extends 'SignalWire::Relay::Event';
has 'restart' => ( is => 'ro', default => sub { 0 } );

# --- Factory method ---
package SignalWire::Relay::Event;

# Map event_type string to class name
my %EVENT_CLASS_MAP = (
    'calling.call.state'             => 'SignalWire::Relay::Event::CallState',
    'calling.call.receive'           => 'SignalWire::Relay::Event::CallReceive',
    'calling.call.dial'              => 'SignalWire::Relay::Event::CallDial',
    'calling.call.connect'           => 'SignalWire::Relay::Event::CallConnect',
    'calling.call.disconnect'        => 'SignalWire::Relay::Event::CallDisconnect',
    'calling.call.play'              => 'SignalWire::Relay::Event::CallPlay',
    'calling.call.record'            => 'SignalWire::Relay::Event::CallRecord',
    'calling.call.collect'           => 'SignalWire::Relay::Event::CallCollect',
    'calling.call.detect'            => 'SignalWire::Relay::Event::CallDetect',
    'calling.call.fax'               => 'SignalWire::Relay::Event::CallFax',
    'calling.call.tap'               => 'SignalWire::Relay::Event::CallTap',
    'calling.call.stream'            => 'SignalWire::Relay::Event::CallStream',
    'calling.call.transcribe'        => 'SignalWire::Relay::Event::CallTranscribe',
    'calling.call.pay'               => 'SignalWire::Relay::Event::CallPay',
    'calling.call.send_digits'       => 'SignalWire::Relay::Event::CallSendDigits',
    'calling.call.refer'             => 'SignalWire::Relay::Event::CallRefer',
    'calling.conference'             => 'SignalWire::Relay::Event::Conference',
    'calling.call.ai'                => 'SignalWire::Relay::Event::CallAI',
    'messaging.receive'              => 'SignalWire::Relay::Event::MessageReceive',
    'messaging.state'                => 'SignalWire::Relay::Event::MessageState',
    'signalwire.authorization.state' => 'SignalWire::Relay::Event::AuthorizationState',
    'signalwire.disconnect'          => 'SignalWire::Relay::Event::Disconnect',
);

sub parse_event {
    my ($class_or_self, $event_type, $params) = @_;
    $params //= {};

    my $event_class = $EVENT_CLASS_MAP{$event_type};
    unless ($event_class) {
        # Return base event for unknown types
        return SignalWire::Relay::Event->new(
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
