#!/usr/bin/perl

# NIP-90: Data Vending Machine
# https://github.com/nostr-protocol/nips/blob/master/90.md

use strictures 2;

use Test2::V0 -no_srand => 1;
use JSON ();

use Net::Nostr::Event;
use Net::Nostr::DVM;
use Net::Nostr::AppHandler;

my $PK  = 'a' x 64;
my $PK2 = 'b' x 64;
my $EID = 'e' x 64;

###############################################################################
# Kind ranges
# "5000-5999 Job request kinds"
# "6000-6999 Job result"
# "7000 Job feedback"
###############################################################################

subtest 'kind range helpers' => sub {
    ok(Net::Nostr::DVM->is_job_request(5000), '5000 is request');
    ok(Net::Nostr::DVM->is_job_request(5999), '5999 is request');
    ok(!Net::Nostr::DVM->is_job_request(4999), '4999 is not request');
    ok(!Net::Nostr::DVM->is_job_request(6000), '6000 is not request');

    ok(Net::Nostr::DVM->is_job_result(6000), '6000 is result');
    ok(Net::Nostr::DVM->is_job_result(6999), '6999 is result');
    ok(!Net::Nostr::DVM->is_job_result(5999), '5999 is not result');
    ok(!Net::Nostr::DVM->is_job_result(7000), '7000 is not result');

    ok(Net::Nostr::DVM->is_job_feedback(7000), '7000 is feedback');
    ok(!Net::Nostr::DVM->is_job_feedback(7001), '7001 is not feedback');
    ok(!Net::Nostr::DVM->is_job_feedback(6999), '6999 is not feedback');
};

###############################################################################
# "Job results always use a kind number that is 1000 higher than the job
#  request kind."
###############################################################################

subtest 'result_kind / request_kind' => sub {
    is(Net::Nostr::DVM->result_kind(5001), 6001, '5001 -> 6001');
    is(Net::Nostr::DVM->result_kind(5000), 6000, '5000 -> 6000');
    is(Net::Nostr::DVM->result_kind(5999), 6999, '5999 -> 6999');

    is(Net::Nostr::DVM->request_kind(6001), 5001, '6001 -> 5001');
    is(Net::Nostr::DVM->request_kind(6000), 5000, '6000 -> 5000');
    is(Net::Nostr::DVM->request_kind(6999), 5999, '6999 -> 5999');
};

###############################################################################
# Job request (kind:5000-5999)
###############################################################################

subtest 'job_request: creates event in 5000-5999 range' => sub {
    my $event = Net::Nostr::DVM->job_request(
        pubkey => $PK,
        kind   => 5001,
    );
    is($event->kind, 5001, 'kind is 5001');
    is($event->content, '', 'content defaults to empty');
};

subtest 'job_request: spec example' => sub {
    my $event = Net::Nostr::DVM->job_request(
        pubkey  => $PK,
        kind    => 5001,
        inputs  => [
            ['https://example.com/audio.mp3', 'url'],
            [$EID, 'event', 'wss://relay.com'],
            ['some text input', 'text'],
        ],
        output  => 'text/plain',
        relays  => ['wss://relay1.com', 'wss://relay2.com'],
        bid     => '5000',
        hashtags => ['bitcoin'],
    );

    my @i = grep { $_->[0] eq 'i' } @{$event->tags};
    is(scalar @i, 3, 'three i tags');
    is($i[0][1], 'https://example.com/audio.mp3');
    is($i[0][2], 'url');
    is($i[1][1], $EID);
    is($i[1][2], 'event');
    is($i[1][3], 'wss://relay.com');
    is($i[2][1], 'some text input');
    is($i[2][2], 'text');

    my @o = grep { $_->[0] eq 'output' } @{$event->tags};
    is($o[0][1], 'text/plain');

    my @r = grep { $_->[0] eq 'relays' } @{$event->tags};
    is($r[0][1], 'wss://relay1.com');
    is($r[0][2], 'wss://relay2.com');

    my @b = grep { $_->[0] eq 'bid' } @{$event->tags};
    is($b[0][1], '5000');

    my @t = grep { $_->[0] eq 't' } @{$event->tags};
    is($t[0][1], 'bitcoin');
};

subtest 'job_request: requires kind in 5000-5999' => sub {
    like(dies { Net::Nostr::DVM->job_request(pubkey => $PK, kind => 4999) },
        qr/5000.*5999|range/i, 'kind 4999 rejected');
    like(dies { Net::Nostr::DVM->job_request(pubkey => $PK, kind => 6000) },
        qr/5000.*5999|range/i, 'kind 6000 rejected');
};

subtest 'job_request: all tags are optional' => sub {
    my $event = Net::Nostr::DVM->job_request(
        pubkey => $PK,
        kind   => 5000,
    );
    is(scalar @{$event->tags}, 0, 'no tags when none specified');
};

###############################################################################
# "i" tag input types
# "MUST be one of: url, event, job, text"
###############################################################################

subtest 'job_request: input type url' => sub {
    my $event = Net::Nostr::DVM->job_request(
        pubkey => $PK, kind => 5001,
        inputs => [['https://example.com/data', 'url']],
    );
    my @i = grep { $_->[0] eq 'i' } @{$event->tags};
    is($i[0][2], 'url');
};

subtest 'job_request: input type event with relay' => sub {
    my $event = Net::Nostr::DVM->job_request(
        pubkey => $PK, kind => 5001,
        inputs => [[$EID, 'event', 'wss://relay.com']],
    );
    my @i = grep { $_->[0] eq 'i' } @{$event->tags};
    is($i[0][2], 'event');
    is($i[0][3], 'wss://relay.com');
};

subtest 'job_request: input type job (chaining)' => sub {
    my $job_id = 'f' x 64;
    my $event = Net::Nostr::DVM->job_request(
        pubkey => $PK, kind => 5001,
        inputs => [[$job_id, 'job', 'wss://relay.com']],
    );
    my @i = grep { $_->[0] eq 'i' } @{$event->tags};
    is($i[0][2], 'job');
    is($i[0][3], 'wss://relay.com');
};

subtest 'job_request: input type text' => sub {
    my $event = Net::Nostr::DVM->job_request(
        pubkey => $PK, kind => 5001,
        inputs => [['hello world', 'text']],
    );
    my @i = grep { $_->[0] eq 'i' } @{$event->tags};
    is($i[0][1], 'hello world');
    is($i[0][2], 'text');
};

subtest 'job_request: input with marker' => sub {
    my $event = Net::Nostr::DVM->job_request(
        pubkey => $PK, kind => 5001,
        inputs => [['data', 'text', '', 'source']],
    );
    my @i = grep { $_->[0] eq 'i' } @{$event->tags};
    is($i[0][4], 'source', 'marker preserved');
};

###############################################################################
# "param": Optional parameters for the job
###############################################################################

subtest 'job_request: params' => sub {
    my $event = Net::Nostr::DVM->job_request(
        pubkey => $PK, kind => 5001,
        params => [['lang', 'es'], ['model', 'gpt-4']],
    );
    my @p = grep { $_->[0] eq 'param' } @{$event->tags};
    is(scalar @p, 2, 'two param tags');
    is($p[0][1], 'lang');
    is($p[0][2], 'es');
    is($p[1][1], 'model');
    is($p[1][2], 'gpt-4');
};

###############################################################################
# "p": Service Providers the customer is interested in
###############################################################################

subtest 'job_request: providers' => sub {
    my $event = Net::Nostr::DVM->job_request(
        pubkey    => $PK, kind => 5001,
        providers => [$PK2],
    );
    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @p, 1, 'one p tag');
    is($p[0][1], $PK2);
};

subtest 'job_request: multiple providers' => sub {
    my $pk3 = 'c' x 64;
    my $event = Net::Nostr::DVM->job_request(
        pubkey    => $PK, kind => 5001,
        providers => [$PK2, $pk3],
    );
    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @p, 2, 'two p tags');
    is($p[0][1], $PK2);
    is($p[1][1], $pk3);
};

###############################################################################
# Encrypted params
# "Add a tag encrypted as tags"
###############################################################################

subtest 'job_request: encrypted flag' => sub {
    my $event = Net::Nostr::DVM->job_request(
        pubkey    => $PK, kind => 5001,
        content   => 'encrypted-payload-here',
        providers => [$PK2],
        encrypted => 1,
    );
    my @enc = grep { $_->[0] eq 'encrypted' } @{$event->tags};
    is(scalar @enc, 1, 'encrypted tag present');
    is($event->content, 'encrypted-payload-here');
};

###############################################################################
# Job result (kind:6000-6999)
###############################################################################

subtest 'job_result: creates event with kind = request + 1000' => sub {
    my $request = Net::Nostr::DVM->job_request(
        pubkey => $PK, kind => 5001,
        inputs => [['hello', 'text']],
    );
    my $result = Net::Nostr::DVM->job_result(
        pubkey   => $PK2,
        request  => $request,
        content  => 'result payload',
    );
    is($result->kind, 6001, 'kind is 6001');
    is($result->content, 'result payload');
};

subtest 'job_result: spec example tags' => sub {
    my $request = Net::Nostr::DVM->job_request(
        pubkey => $PK, kind => 5001,
        inputs => [['hello', 'text']],
    );
    my $result = Net::Nostr::DVM->job_result(
        pubkey     => $PK2,
        request    => $request,
        relay_hint => 'wss://relay.com',
        amount     => '5000',
        bolt11     => 'lnbc1...',
        content    => 'output data',
    );

    # request tag: stringified JSON of the original request
    my @req = grep { $_->[0] eq 'request' } @{$result->tags};
    is(scalar @req, 1, 'one request tag');
    my $decoded = JSON::decode_json($req[0][1]);
    is($decoded->{kind}, 5001, 'request JSON has correct kind');

    # e tag: job request id
    my @e = grep { $_->[0] eq 'e' } @{$result->tags};
    is(scalar @e, 1, 'one e tag');
    is($e[0][1], $request->id, 'references job request id');
    is($e[0][2], 'wss://relay.com', 'relay hint');

    # i tag: original inputs
    my @i = grep { $_->[0] eq 'i' } @{$result->tags};
    is(scalar @i, 1, 'one i tag from request');
    is($i[0][1], 'hello');
    is($i[0][2], 'text');

    # p tag: customer's pubkey
    my @p = grep { $_->[0] eq 'p' } @{$result->tags};
    is(scalar @p, 1, 'one p tag');
    is($p[0][1], $PK, 'customer pubkey');

    # amount tag
    my @amt = grep { $_->[0] eq 'amount' } @{$result->tags};
    is($amt[0][1], '5000');
    is($amt[0][2], 'lnbc1...');
};

subtest 'job_result: requires kind in 6000-6999' => sub {
    my $request = Net::Nostr::DVM->job_request(
        pubkey => $PK, kind => 5001,
    );
    # Direct kind override should be rejected if out of range
    like(dies { Net::Nostr::DVM->job_result(
        pubkey => $PK2, request => $request, kind => 5001,
    ) }, qr/6000.*6999|range/i, 'kind 5001 rejected for result');
};

subtest 'job_result: multiple inputs from request' => sub {
    my $request = Net::Nostr::DVM->job_request(
        pubkey => $PK, kind => 5001,
        inputs => [
            ['https://example.com/a.mp3', 'url'],
            [$EID, 'event', 'wss://relay.com'],
            ['hello', 'text'],
        ],
    );
    my $result = Net::Nostr::DVM->job_result(
        pubkey  => $PK2,
        request => $request,
        content => 'output',
    );
    my @i = grep { $_->[0] eq 'i' } @{$result->tags};
    is(scalar @i, 3, 'three i tags from request');
    is($i[0][2], 'url');
    is($i[1][2], 'event');
    is($i[1][3], 'wss://relay.com', 'relay preserved');
    is($i[2][2], 'text');
};

subtest 'job_result: amount without bolt11' => sub {
    my $request = Net::Nostr::DVM->job_request(
        pubkey => $PK, kind => 5001,
    );
    my $result = Net::Nostr::DVM->job_result(
        pubkey  => $PK2,
        request => $request,
        amount  => '1000',
        content => 'output',
    );
    my @amt = grep { $_->[0] eq 'amount' } @{$result->tags};
    is(scalar @{$amt[0]}, 2, 'amount tag has 2 elements (no bolt11)');
};

###############################################################################
# Encrypted output
# "If the request has encrypted params, then output should be encrypted"
###############################################################################

subtest 'job_result: encrypted output' => sub {
    my $request = Net::Nostr::DVM->job_request(
        pubkey    => $PK, kind => 5001,
        providers => [$PK2],
        encrypted => 1,
        content   => 'encrypted-input',
    );
    my $result = Net::Nostr::DVM->job_result(
        pubkey    => $PK2,
        request   => $request,
        content   => 'encrypted-output',
        encrypted => 1,
    );
    my @enc = grep { $_->[0] eq 'encrypted' } @{$result->tags};
    is(scalar @enc, 1, 'encrypted tag present');
    # "avoid including i tag with input-data as clear text"
    my @i = grep { $_->[0] eq 'i' } @{$result->tags};
    is(scalar @i, 0, 'no i tags when encrypted');
};

###############################################################################
# Job feedback (kind:7000)
###############################################################################

subtest 'job_feedback: creates kind 7000 event' => sub {
    my $event = Net::Nostr::DVM->job_feedback(
        pubkey     => $PK2,
        request_id => $EID,
        customer   => $PK,
        status     => 'processing',
    );
    is($event->kind, 7000, 'kind is 7000');
};

subtest 'job_feedback: spec example' => sub {
    my $event = Net::Nostr::DVM->job_feedback(
        pubkey     => $PK2,
        request_id => $EID,
        relay_hint => 'wss://relay.com',
        customer   => $PK,
        status     => 'payment-required',
        extra_info => 'Please pay to continue',
        amount     => '5000',
        bolt11     => 'lnbc1...',
    );

    my @s = grep { $_->[0] eq 'status' } @{$event->tags};
    is($s[0][1], 'payment-required');
    is($s[0][2], 'Please pay to continue');

    my @amt = grep { $_->[0] eq 'amount' } @{$event->tags};
    is($amt[0][1], '5000');
    is($amt[0][2], 'lnbc1...');

    my @e = grep { $_->[0] eq 'e' } @{$event->tags};
    is($e[0][1], $EID);
    is($e[0][2], 'wss://relay.com');

    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is($p[0][1], $PK);

    is($event->content, '');
};

###############################################################################
# Job feedback status values
# payment-required, processing, error, success, partial
###############################################################################

subtest 'job_feedback: all status values' => sub {
    for my $status (qw(payment-required processing error success partial)) {
        my $event = Net::Nostr::DVM->job_feedback(
            pubkey => $PK2, request_id => $EID, customer => $PK,
            status => $status,
        );
        my @s = grep { $_->[0] eq 'status' } @{$event->tags};
        is($s[0][1], $status, "status: $status");
    }
};

subtest 'job_feedback: partial with content' => sub {
    my $event = Net::Nostr::DVM->job_feedback(
        pubkey     => $PK2,
        request_id => $EID,
        customer   => $PK,
        status     => 'partial',
        content    => 'partial results sample',
    );
    is($event->content, 'partial results sample');
};

subtest 'job_feedback: amount without bolt11' => sub {
    my $event = Net::Nostr::DVM->job_feedback(
        pubkey     => $PK2,
        request_id => $EID,
        customer   => $PK,
        status     => 'payment-required',
        amount     => '3000',
    );
    my @amt = grep { $_->[0] eq 'amount' } @{$event->tags};
    is(scalar @{$amt[0]}, 2, 'amount tag has 2 elements (no bolt11)');
};

subtest 'job_feedback: requires request_id, customer, status' => sub {
    like(dies { Net::Nostr::DVM->job_feedback(
        pubkey => $PK2, customer => $PK, status => 'processing',
    ) }, qr/request_id/, 'missing request_id');
    like(dies { Net::Nostr::DVM->job_feedback(
        pubkey => $PK2, request_id => $EID, status => 'processing',
    ) }, qr/customer/, 'missing customer');
    like(dies { Net::Nostr::DVM->job_feedback(
        pubkey => $PK2, request_id => $EID, customer => $PK,
    ) }, qr/status/, 'missing status');
};

###############################################################################
# from_event: parse all three types
###############################################################################

subtest 'from_event: job request' => sub {
    my $event = Net::Nostr::DVM->job_request(
        pubkey   => $PK, kind => 5001,
        inputs   => [['hello', 'text'], [$EID, 'event', 'wss://r.com']],
        output   => 'text/plain',
        params   => [['lang', 'es']],
        bid      => '5000',
        relays   => ['wss://relay.com'],
        providers => [$PK2],
        hashtags => ['bitcoin'],
    );
    my $parsed = Net::Nostr::DVM->from_event($event);
    is(scalar @{$parsed->inputs}, 2, 'two inputs');
    is($parsed->inputs->[0][0], 'hello');
    is($parsed->inputs->[0][1], 'text');
    is($parsed->inputs->[1][0], $EID);
    is($parsed->inputs->[1][1], 'event');
    is($parsed->inputs->[1][2], 'wss://r.com');
    is($parsed->output, 'text/plain');
    is($parsed->params->[0][0], 'lang');
    is($parsed->params->[0][1], 'es');
    is($parsed->bid, '5000');
    is($parsed->relays->[0], 'wss://relay.com');
    is($parsed->providers->[0], $PK2);
    is($parsed->hashtags->[0], 'bitcoin');
};

subtest 'from_event: job result' => sub {
    my $request = Net::Nostr::DVM->job_request(
        pubkey => $PK, kind => 5001,
        inputs => [['hello', 'text']],
    );
    my $result = Net::Nostr::DVM->job_result(
        pubkey     => $PK2,
        request    => $request,
        relay_hint => 'wss://relay.com',
        amount     => '5000',
        bolt11     => 'lnbc1...',
        content    => 'output',
    );
    my $parsed = Net::Nostr::DVM->from_event($result);
    is($parsed->request_id, $request->id);
    is($parsed->relay_hint, 'wss://relay.com');
    is($parsed->customer, $PK);
    is($parsed->amount, '5000');
    is($parsed->bolt11, 'lnbc1...');
    ok($parsed->request_event, 'request_event parsed');
    is(scalar @{$parsed->inputs}, 1);
};

subtest 'from_event: job feedback' => sub {
    my $event = Net::Nostr::DVM->job_feedback(
        pubkey     => $PK2,
        request_id => $EID,
        relay_hint => 'wss://relay.com',
        customer   => $PK,
        status     => 'processing',
        extra_info => 'Working on it',
        amount     => '1000',
    );
    my $parsed = Net::Nostr::DVM->from_event($event);
    is($parsed->status, 'processing');
    is($parsed->extra_info, 'Working on it');
    is($parsed->request_id, $EID);
    is($parsed->relay_hint, 'wss://relay.com');
    is($parsed->customer, $PK);
    is($parsed->amount, '1000');
};

subtest 'from_event: encrypted job request round-trip' => sub {
    my $event = Net::Nostr::DVM->job_request(
        pubkey    => $PK, kind => 5001,
        content   => 'encrypted-params',
        providers => [$PK2],
        encrypted => 1,
    );
    my $parsed = Net::Nostr::DVM->from_event($event);
    ok($parsed->encrypted, 'encrypted flag parsed');
    is($parsed->providers->[0], $PK2, 'provider parsed');
};

subtest 'from_event: encrypted job result round-trip' => sub {
    my $request = Net::Nostr::DVM->job_request(
        pubkey    => $PK, kind => 5001,
        providers => [$PK2],
        encrypted => 1,
        content   => 'encrypted-input',
    );
    my $result = Net::Nostr::DVM->job_result(
        pubkey    => $PK2,
        request   => $request,
        content   => 'encrypted-output',
        encrypted => 1,
    );
    my $parsed = Net::Nostr::DVM->from_event($result);
    ok($parsed->encrypted, 'encrypted flag parsed on result');
    is(scalar @{$parsed->inputs}, 0, 'no inputs when encrypted');
};

subtest 'from_event: returns undef for unrecognized kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => '', tags => [],
    );
    is(Net::Nostr::DVM->from_event($event), undef);
};

###############################################################################
# validate
###############################################################################

subtest 'validate: job request' => sub {
    my $event = Net::Nostr::DVM->job_request(
        pubkey => $PK, kind => 5001,
    );
    ok(Net::Nostr::DVM->validate($event), 'valid request');
};

subtest 'validate: job result' => sub {
    my $request = Net::Nostr::DVM->job_request(pubkey => $PK, kind => 5001);
    my $result = Net::Nostr::DVM->job_result(
        pubkey => $PK2, request => $request, content => 'out',
    );
    ok(Net::Nostr::DVM->validate($result), 'valid result');
};

subtest 'validate: job result missing e tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK2, kind => 6001, content => 'out',
        tags => [['p', $PK], ['request', '{}']],
    );
    like(dies { Net::Nostr::DVM->validate($event) }, qr/e.*tag/i);
};

subtest 'validate: job result missing p tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK2, kind => 6001, content => 'out',
        tags => [['e', $EID], ['request', '{}']],
    );
    like(dies { Net::Nostr::DVM->validate($event) }, qr/p.*tag/i);
};

subtest 'validate: job result missing request tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK2, kind => 6001, content => 'out',
        tags => [['e', $EID], ['p', $PK]],
    );
    like(dies { Net::Nostr::DVM->validate($event) }, qr/request.*tag/i);
};

subtest 'validate: job feedback' => sub {
    my $event = Net::Nostr::DVM->job_feedback(
        pubkey => $PK2, request_id => $EID, customer => $PK,
        status => 'processing',
    );
    ok(Net::Nostr::DVM->validate($event), 'valid feedback');
};

subtest 'validate: job feedback missing status tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK2, kind => 7000, content => '',
        tags => [['e', $EID], ['p', $PK]],
    );
    like(dies { Net::Nostr::DVM->validate($event) }, qr/status.*tag/i);
};

subtest 'validate: job feedback missing e tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK2, kind => 7000, content => '',
        tags => [['status', 'processing'], ['p', $PK]],
    );
    like(dies { Net::Nostr::DVM->validate($event) }, qr/e.*tag/i);
};

subtest 'validate: job feedback missing p tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK2, kind => 7000, content => '',
        tags => [['status', 'processing'], ['e', $EID]],
    );
    like(dies { Net::Nostr::DVM->validate($event) }, qr/p.*tag/i);
};

subtest 'validate: wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => '', tags => [],
    );
    like(dies { Net::Nostr::DVM->validate($event) }, qr/kind/i);
};

###############################################################################
# Encrypted feedback
# "If the input params requires input to be encrypted, then content field
#  will have encrypted payload with p tag as key"
###############################################################################

subtest 'job_feedback: encrypted flag' => sub {
    my $event = Net::Nostr::DVM->job_feedback(
        pubkey     => $PK2,
        request_id => $EID,
        customer   => $PK,
        status     => 'success',
        content    => 'encrypted-feedback-payload',
        encrypted  => 1,
    );
    my @enc = grep { $_->[0] eq 'encrypted' } @{$event->tags};
    is(scalar @enc, 1, 'encrypted tag present');
    is($event->content, 'encrypted-feedback-payload');
};

subtest 'job_feedback: encrypted round-trip' => sub {
    my $event = Net::Nostr::DVM->job_feedback(
        pubkey     => $PK2,
        request_id => $EID,
        customer   => $PK,
        status     => 'processing',
        encrypted  => 1,
    );
    my $parsed = Net::Nostr::DVM->from_event($event);
    ok($parsed->encrypted, 'encrypted flag round-trips');
};

###############################################################################
# Cancellation
# "A job request might be canceled by publishing a kind:5 delete request
#  event tagging the job request event."
###############################################################################

subtest 'cancellation: kind 5 delete references job request' => sub {
    my $request = Net::Nostr::DVM->job_request(
        pubkey => $PK, kind => 5001,
        inputs => [['hello', 'text']],
    );

    # Cancellation is a standard NIP-09 kind 5 event
    my $delete = Net::Nostr::Event->new(
        pubkey  => $PK,
        kind    => 5,
        content => 'cancel job',
        tags    => [['e', $request->id]],
    );
    is($delete->kind, 5, 'cancel is kind 5');
    my @e = grep { $_->[0] eq 'e' } @{$delete->tags};
    is($e[0][1], $request->id, 'references job request id');
};

###############################################################################
# Job chaining (Appendix 1)
# "A Customer MAY request multiple jobs to be processed as a chain"
###############################################################################

subtest 'job chaining: input type job' => sub {
    my $job1 = Net::Nostr::DVM->job_request(
        pubkey => $PK, kind => 5001,
        inputs => [['https://example.com/podcast.mp3', 'url']],
    );
    my $job2 = Net::Nostr::DVM->job_request(
        pubkey => $PK, kind => 5002,
        inputs => [[$job1->id, 'job', 'wss://relay.com']],
    );
    my @i = grep { $_->[0] eq 'i' } @{$job2->tags};
    is($i[0][1], $job1->id, 'references first job');
    is($i[0][2], 'job', 'input type is job');
};

###############################################################################
# SP discoverability (Appendix 2)
# "Service Providers MAY use NIP-89 announcements"
# Kind 31990 is handled by AppHandler module, just verify awareness
###############################################################################

subtest 'SP discoverability: kind constant' => sub {
    is(Net::Nostr::DVM::SP_DISCOVERY_KIND, 31990);
};

subtest 'SP discoverability: NIP-89 announcement with k tag' => sub {
    # Spec example: kind 31990 with ["k", "5005"] and ["t", "bitcoin"]
    my $event = Net::Nostr::AppHandler->handler(
        pubkey     => $PK2,
        identifier => 'translating-dvm',
        kinds      => [5005],
        content    => JSON::encode_json({
            name  => 'Translating DVM',
            about => "I'm a DVM specialized in translating Bitcoin content.",
        }),
    );
    is($event->kind, Net::Nostr::DVM::SP_DISCOVERY_KIND, 'kind 31990');
    my @k = grep { $_->[0] eq 'k' } @{$event->tags};
    is(scalar @k, 1, 'one k tag');
    is($k[0][1], '5005', 'advertises supported job kind');
};

###############################################################################
# Round-trip: build -> from_event
###############################################################################

subtest 'round-trip: job request' => sub {
    my $event = Net::Nostr::DVM->job_request(
        pubkey   => $PK, kind => 5001,
        inputs   => [['hello', 'text']],
        output   => 'text/plain',
        params   => [['lang', 'en']],
        bid      => '3000',
    );
    my $parsed = Net::Nostr::DVM->from_event($event);
    is($parsed->inputs->[0][0], 'hello');
    is($parsed->output, 'text/plain');
    is($parsed->params->[0][0], 'lang');
    is($parsed->params->[0][1], 'en');
    is($parsed->bid, '3000');
};

subtest 'round-trip: job feedback' => sub {
    my $event = Net::Nostr::DVM->job_feedback(
        pubkey     => $PK2,
        request_id => $EID,
        customer   => $PK,
        status     => 'success',
        extra_info => 'Done!',
    );
    my $parsed = Net::Nostr::DVM->from_event($event);
    is($parsed->status, 'success');
    is($parsed->extra_info, 'Done!');
};

done_testing;
