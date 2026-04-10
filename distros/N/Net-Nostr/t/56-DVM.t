use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::DVM;

my $PK  = 'a' x 64;
my $PK2 = 'b' x 64;
my $EID = 'e' x 64;

###############################################################################
# POD example: job_request
###############################################################################

subtest 'POD: job_request' => sub {
    my $event = Net::Nostr::DVM->job_request(
        pubkey => $PK,
        kind   => 5001,
        inputs => [['https://example.com/audio.mp3', 'url']],
        output => 'text/plain',
    );
    is($event->kind, 5001, 'kind');
};

###############################################################################
# POD example: job_result
###############################################################################

subtest 'POD: job_result' => sub {
    my $request = Net::Nostr::DVM->job_request(
        pubkey => $PK, kind => 5001,
    );
    my $result = Net::Nostr::DVM->job_result(
        pubkey  => $PK2,
        request => $request,
        content => 'Transcribed text here.',
        amount  => '5000',
    );
    is($result->kind, 6001, 'kind');
};

###############################################################################
# POD example: job_feedback
###############################################################################

subtest 'POD: job_feedback' => sub {
    my $event = Net::Nostr::DVM->job_feedback(
        pubkey     => $PK2,
        request_id => $EID,
        customer   => $PK,
        status     => 'processing',
    );
    is($event->kind, 7000, 'kind');
};

###############################################################################
# POD example: from_event
###############################################################################

subtest 'POD: from_event' => sub {
    my $event = Net::Nostr::DVM->job_request(
        pubkey => $PK, kind => 5001,
        inputs => [['test', 'text']],
    );
    my $parsed = Net::Nostr::DVM->from_event($event);
    is($parsed->inputs->[0][0], 'test');
};

###############################################################################
# POD example: validate
###############################################################################

subtest 'POD: validate' => sub {
    my $event = Net::Nostr::DVM->job_request(
        pubkey => $PK, kind => 5001,
    );
    ok(Net::Nostr::DVM->validate($event), 'validate returns true');
};

###############################################################################
# POD example: kind helpers
###############################################################################

subtest 'POD: kind helpers' => sub {
    ok(Net::Nostr::DVM->is_job_request(5001));
    ok(Net::Nostr::DVM->is_job_result(6001));
    ok(Net::Nostr::DVM->is_job_feedback(7000));
    is(Net::Nostr::DVM->result_kind(5001), 6001);
    is(Net::Nostr::DVM->request_kind(6001), 5001);
};

###############################################################################
# POD example: SP_DISCOVERY_KIND
###############################################################################

subtest 'POD: SP_DISCOVERY_KIND' => sub {
    my $kind = Net::Nostr::DVM::SP_DISCOVERY_KIND;
    is($kind, 31990, 'SP_DISCOVERY_KIND is 31990');
};

###############################################################################
# POD example: new
###############################################################################

subtest 'POD: new' => sub {
    my $dvm = Net::Nostr::DVM->new(
        status => 'processing',
    );
    is($dvm->status, 'processing');
};

###############################################################################
# Constructor: unknown args rejected
###############################################################################

subtest 'constructor: unknown args rejected' => sub {
    like(
        dies { Net::Nostr::DVM->new(bogus => 1) },
        qr/unknown/i,
        'unknown arg rejected'
    );
};

###############################################################################
# Public methods available
###############################################################################

subtest 'public methods available' => sub {
    can_ok('Net::Nostr::DVM',
        qw(new job_request job_result job_feedback
           from_event validate
           is_job_request is_job_result is_job_feedback
           result_kind request_kind
           inputs output params bid relays providers hashtags
           request_id request_event relay_hint customer
           amount bolt11 status extra_info encrypted));
};

done_testing;
