#!/usr/bin/env perl
# rest_audit_harness.pl
#
# Driver for porting-sdk/scripts/audit_rest_transport.py. The audit
# stands up a local HTTP fixture on 127.0.0.1:NNNN that records every
# request and serves a per-probe canned JSON response containing a
# sentinel value the audit watches for. The harness reads:
#
#   REST_OPERATION       — dotted name like "calling.list_calls"
#   REST_OPERATION_ARGS  — JSON-encoded dict of args
#   REST_FIXTURE_URL     — full URL of the fixture, e.g. http://127.0.0.1:NNNN
#   SIGNALWIRE_PROJECT_ID, SIGNALWIRE_API_TOKEN, SIGNALWIRE_SPACE — credentials
#                          (the fixture doesn't validate but the SDK requires them)
#
# Constructs a SignalWire::REST::RestClient pointed at the fixture URL,
# routes the operation to the appropriate namespace, prints the parsed
# return as JSON to stdout, exits 0.
#
# The 5 operations the audit probes:
#   - calling.list_calls            → compat.calls.list (LAML compat path)
#   - messaging.send                → compat.messages.create
#   - phone_numbers.list            → phone_numbers.list (relay rest)
#   - fabric.subscribers.list       → fabric.subscribers.list
#   - compatibility.calls.list      → compat.calls.list (alias for the LAML path)

use strict;
use warnings;
use lib 'lib';

use JSON ();
use SignalWire::REST::RestClient;

sub die_with {
    my ($msg) = @_;
    print STDERR "rest_audit_harness: $msg\n";
    exit 2;
}

my $operation = $ENV{REST_OPERATION}
    or die_with("REST_OPERATION is not set");
my $fixture_url = $ENV{REST_FIXTURE_URL}
    or die_with("REST_FIXTURE_URL is not set");
my $args_json = $ENV{REST_OPERATION_ARGS} // '{}';
my $project   = $ENV{SIGNALWIRE_PROJECT_ID} // 'audit-project';
my $token     = $ENV{SIGNALWIRE_API_TOKEN}  // 'audit-token';

my $args = eval { JSON::decode_json($args_json) };
die_with("REST_OPERATION_ARGS is not valid JSON: $@") if $@;
$args //= {};

# host accepts a fully-qualified URL — the HttpClient strips/prepends
# scheme as needed.
my $client = SignalWire::REST::RestClient->new(
    project => $project,
    token   => $token,
    host    => $fixture_url,
);

my %dispatchers = (
    'calling.list_calls' => sub {
        # In Python, "calling.list_calls" maps to the LAML compat
        # /Calls listing, not the Relay /api/calling/calls endpoint.
        # The audit's expected_path_substring is
        # "/api/laml/2010-04-01/Accounts" so this is unambiguous.
        my $list = $client->compat->calls->list(%$args);
        return $list;
    },
    'messaging.send' => sub {
        # The audit's expected_path_substring is "Messages" — the
        # LAML compat Messages endpoint, not the Relay messaging RPC.
        # Python's "messaging.send" maps to compat.messages.create.
        my %p = %$args;
        # Python uses `from_` to avoid the reserved keyword; map it
        # to the wire-level `From` field (LAML uses CamelCase). The
        # audit just checks the body got POSTed; field names aren't
        # asserted on the wire side, so simple pass-through works.
        if (exists $p{from_}) {
            $p{from} = delete $p{from_};
        }
        return $client->compat->messages->create(%p);
    },
    'phone_numbers.list' => sub {
        return $client->phone_numbers->list(%$args);
    },
    'fabric.subscribers.list' => sub {
        return $client->fabric->subscribers->list(%$args);
    },
    'compatibility.calls.list' => sub {
        return $client->compat->calls->list(%$args);
    },
);

my $disp = $dispatchers{$operation}
    or die_with("no dispatcher for operation '$operation'");

my $reply = eval { $disp->() };
die_with("operation died: $@") if $@;

# Print the parsed response. The audit checks stdout for the sentinel
# value the fixture seeded into its canned response.
print JSON::encode_json($reply // {});
print "\n";
exit 0;
