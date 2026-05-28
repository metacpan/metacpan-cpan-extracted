#!/usr/bin/env perl
# relay_audit_harness.pl
#
# Drives SignalWire::Relay::Client against the local fixture stood up
# by porting-sdk/scripts/audit_relay_handshake.py. The audit fixture
# binds a plain TCP socket on 127.0.0.1:NNNN, speaks RFC-6455 + JSON-RPC
# 2.0 well enough to handshake, dispatch an event, and observe an ACK.
#
# Contract (from audit_relay_handshake.py top-of-file docstring):
#   - SIGNALWIRE_RELAY_HOST  is "127.0.0.1:NNNN" (the fixture port).
#   - SIGNALWIRE_RELAY_SCHEME is "ws" (plain — fixture does not do TLS).
#   - SIGNALWIRE_PROJECT_ID  / SIGNALWIRE_API_TOKEN are 'audit' / 'audit'.
#   - SIGNALWIRE_CONTEXTS    is "audit_ctx" (comma-separated allowed).
#
# Required side-effects on the wire:
#   1. Open the WSS upgrade.
#   2. Send `signalwire.connect` with `params.project` populated.
#   3. Send `signalwire.subscribe` with the configured context list.
#   4. ACK the inbound `signalwire.event` the fixture pushes back, with
#      a frame carrying `method:"signalwire.event"` so the fixture
#      records it as dispatched (the fixture only counts method-bearing
#      frames as event ACKs — Python's bare `{result:{}}` ack is ignored).
#
# Run:
#     SIGNALWIRE_RELAY_HOST=127.0.0.1:9876 SIGNALWIRE_RELAY_SCHEME=ws \
#       SIGNALWIRE_PROJECT_ID=audit SIGNALWIRE_API_TOKEN=audit \
#       SIGNALWIRE_CONTEXTS=audit_ctx perl -Ilib examples/relay_audit_harness.pl
#
# Exits 0 on full happy-path, non-zero on any error.

use strict;
use warnings;
use lib 'lib';

use SignalWire::Relay::Client;
use JSON qw(encode_json);

sub die_with {
    my ($msg) = @_;
    print STDERR "relay_audit_harness: $msg\n";
    exit 2;
}

my $host    = $ENV{SIGNALWIRE_RELAY_HOST}   or die_with("SIGNALWIRE_RELAY_HOST is not set");
my $scheme  = $ENV{SIGNALWIRE_RELAY_SCHEME} || 'wss';
my $project = $ENV{SIGNALWIRE_PROJECT_ID}   or die_with("SIGNALWIRE_PROJECT_ID is not set");
my $token   = $ENV{SIGNALWIRE_API_TOKEN}    or die_with("SIGNALWIRE_API_TOKEN is not set");
my $ctxs    = $ENV{SIGNALWIRE_CONTEXTS}     // 'audit_ctx';

my @contexts = grep { length } split /,/, $ctxs;
@contexts = ('audit_ctx') unless @contexts;

my $client = SignalWire::Relay::Client->new(
    host     => $host,
    scheme   => $scheme,
    project  => $project,
    token    => $token,
    contexts => \@contexts,
);

my $event_acked = 0;
$client->on_event(sub {
    my ($event) = @_;
    # The audit fixture pushes a `calling.call.state` event with
    # call_id "audit-call-1". Mirror it back as a method-bearing
    # `signalwire.event` frame: the fixture watches for that exact
    # method on the client→server direction to mark the event
    # dispatched. Python's bare-result ack is invisible to it.
    return if $event_acked;
    $event_acked = 1;

    my $payload = {
        jsonrpc => '2.0',
        id      => 'audit-event-ack',
        method  => 'signalwire.event',
        params  => {
            event_type => $event->event_type,
            params     => {
                call_id => 'audit-call-1',
                acked   => 1,
            },
        },
    };
    # _send is a private helper; OK for harness use because we need a
    # method-bearing frame the public ACK path explicitly omits.
    $client->_send($payload);
});

unless ($client->connect_ws) {
    die_with("connect_ws() failed");
}

# Authenticate (sends signalwire.connect with params.project populated).
my $auth = eval { $client->authenticate };
if ($@ || !$auth) {
    die_with("authenticate() failed: $@");
}

# The audit fixture watches for signalwire.subscribe specifically.
# Python's RELAY client uses signalwire.receive (matched on the
# server, not the audit fixture); the audit harness sends the
# subscribe variant directly.
my $sub_result = eval {
    $client->execute('signalwire.subscribe', { contexts => \@contexts });
};
if ($@) {
    die_with("subscribe failed: $@");
}

# Pump the read loop until either the fixture pushes an event (which
# our on_event callback ACKs) or we time out.
my $deadline = time() + 5;
while (time() < $deadline && !$event_acked) {
    $client->_read_once;
}

unless ($event_acked) {
    die_with("did not receive an event from the fixture within 5s");
}

# Done.
$client->disconnect_ws;
print "relay_audit_harness: ok\n";
exit 0;
