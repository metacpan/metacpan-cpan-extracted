package SignalWire::Agents::Relay::Constants;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(
    PROTOCOL_VERSION
    CALL_STATES CALL_STATE_CREATED CALL_STATE_RINGING CALL_STATE_ANSWERED CALL_STATE_ENDING CALL_STATE_ENDED
    CALL_TERMINAL_STATES
    CALL_END_REASONS
    DIAL_STATES DIAL_STATE_DIALING DIAL_STATE_ANSWERED DIAL_STATE_FAILED
    MESSAGE_STATES MESSAGE_STATE_QUEUED MESSAGE_STATE_INITIATED MESSAGE_STATE_SENT
    MESSAGE_STATE_DELIVERED MESSAGE_STATE_UNDELIVERED MESSAGE_STATE_FAILED MESSAGE_STATE_RECEIVED
    MESSAGE_TERMINAL_STATES
    EVENT_TYPES
    ACTION_TERMINAL_STATES
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

# Protocol version for signalwire.connect
use constant PROTOCOL_VERSION => { major => 2, minor => 0, revision => 0 };

# --- Call States ---
use constant CALL_STATE_CREATED  => 'created';
use constant CALL_STATE_RINGING  => 'ringing';
use constant CALL_STATE_ANSWERED => 'answered';
use constant CALL_STATE_ENDING   => 'ending';
use constant CALL_STATE_ENDED    => 'ended';

use constant CALL_STATES => [
    CALL_STATE_CREATED,
    CALL_STATE_RINGING,
    CALL_STATE_ANSWERED,
    CALL_STATE_ENDING,
    CALL_STATE_ENDED,
];

use constant CALL_TERMINAL_STATES => {
    (CALL_STATE_ENDED) => 1,
};

# --- Call End Reasons ---
use constant CALL_END_REASONS => {
    hangup    => 'hangup',
    cancel    => 'cancel',
    busy      => 'busy',
    noAnswer  => 'noAnswer',
    decline   => 'decline',
    error     => 'error',
};

# --- Dial States ---
use constant DIAL_STATE_DIALING  => 'dialing';
use constant DIAL_STATE_ANSWERED => 'answered';
use constant DIAL_STATE_FAILED   => 'failed';

use constant DIAL_STATES => [
    DIAL_STATE_DIALING,
    DIAL_STATE_ANSWERED,
    DIAL_STATE_FAILED,
];

# --- Message States ---
use constant MESSAGE_STATE_QUEUED      => 'queued';
use constant MESSAGE_STATE_INITIATED   => 'initiated';
use constant MESSAGE_STATE_SENT        => 'sent';
use constant MESSAGE_STATE_DELIVERED   => 'delivered';
use constant MESSAGE_STATE_UNDELIVERED => 'undelivered';
use constant MESSAGE_STATE_FAILED      => 'failed';
use constant MESSAGE_STATE_RECEIVED    => 'received';

use constant MESSAGE_STATES => [
    MESSAGE_STATE_QUEUED,
    MESSAGE_STATE_INITIATED,
    MESSAGE_STATE_SENT,
    MESSAGE_STATE_DELIVERED,
    MESSAGE_STATE_UNDELIVERED,
    MESSAGE_STATE_FAILED,
    MESSAGE_STATE_RECEIVED,
];

use constant MESSAGE_TERMINAL_STATES => {
    (MESSAGE_STATE_DELIVERED)   => 1,
    (MESSAGE_STATE_UNDELIVERED) => 1,
    (MESSAGE_STATE_FAILED)      => 1,
};

# --- Event Types ---
use constant EVENT_TYPES => {
    # Call state events
    'calling.call.state'            => 'CallState',
    'calling.call.receive'          => 'CallReceive',
    'calling.call.dial'             => 'CallDial',
    'calling.call.connect'          => 'CallConnect',
    'calling.call.disconnect'       => 'CallDisconnect',

    # Action events
    'calling.call.play'             => 'CallPlay',
    'calling.call.record'           => 'CallRecord',
    'calling.call.collect'          => 'CallCollect',
    'calling.call.detect'           => 'CallDetect',
    'calling.call.fax'              => 'CallFax',
    'calling.call.tap'              => 'CallTap',
    'calling.call.stream'           => 'CallStream',
    'calling.call.transcribe'       => 'CallTranscribe',
    'calling.call.pay'              => 'CallPay',
    'calling.call.send_digits'      => 'CallSendDigits',
    'calling.call.refer'            => 'CallRefer',

    # Conference events
    'calling.conference'            => 'Conference',

    # AI events
    'calling.call.ai'               => 'CallAI',

    # Messaging events
    'messaging.receive'             => 'MessageReceive',
    'messaging.state'               => 'MessageState',

    # System events
    'signalwire.authorization.state' => 'AuthorizationState',
    'signalwire.disconnect'          => 'Disconnect',
};

# --- Action Terminal States (per event type) ---
use constant ACTION_TERMINAL_STATES => {
    'calling.call.play'       => { finished => 1, error => 1 },
    'calling.call.record'     => { finished => 1, no_input => 1 },
    'calling.call.detect'     => { finished => 1, error => 1 },
    'calling.call.collect'    => { finished => 1, error => 1, no_input => 1, no_match => 1 },
    'calling.call.fax'        => { finished => 1, error => 1 },
    'calling.call.tap'        => { finished => 1 },
    'calling.call.stream'     => { finished => 1 },
    'calling.call.transcribe' => { finished => 1 },
    'calling.call.pay'        => { finished => 1, error => 1 },
};

1;
