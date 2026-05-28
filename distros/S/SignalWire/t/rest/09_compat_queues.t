#!/usr/bin/env perl
# Mock-backed unit tests translated from
# signalwire-python/tests/unit/rest/test_compat_queues.py.
#
# Covers CompatQueues.update / list_members / get_member / dequeue_member.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use MockTest;

my $BASE = '/api/laml/2010-04-01/Accounts/test_proj/Queues';

subtest 'TestCompatQueuesUpdate' => sub {
    subtest 'test_returns_queue_resource' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->queues->update(
            'QU_U', FriendlyName => 'updated',
        );
        is(ref $result, 'HASH', 'expected hashref');
        # Queue resources expose friendly_name + sid + max_size.
        ok(exists $result->{friendly_name} || exists $result->{sid},
            'has friendly_name or sid');
    };

    subtest 'test_journal_records_post_with_friendly_name' => sub {
        my $client = MockTest::client();
        $client->compat->queues->update(
            'QU_UU',
            FriendlyName => 'renamed',
            MaxSize      => 200,
        );
        my $j = MockTest::journal_last();
        is($j->{method}, 'POST', 'POST recorded');
        is($j->{path}, "$BASE/QU_UU", 'path matches');
        is(ref $j->{body}, 'HASH', 'body is hashref');
        is($j->{body}{FriendlyName}, 'renamed', 'FriendlyName forwarded');
        is($j->{body}{MaxSize}, 200, 'MaxSize forwarded');
    };
};

subtest 'TestCompatQueuesListMembers' => sub {
    subtest 'test_returns_paginated_members' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->queues->list_members('QU_LM');
        is(ref $result, 'HASH', 'expected hashref');
        ok(exists $result->{queue_members},
            "missing 'queue_members' key, got " . join(',', sort keys %$result));
        is(ref $result->{queue_members}, 'ARRAY', 'queue_members is arrayref');
    };

    subtest 'test_journal_records_get_to_members' => sub {
        my $client = MockTest::client();
        $client->compat->queues->list_members('QU_LMX');
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path}, "$BASE/QU_LMX/Members", 'path matches');
    };
};

subtest 'TestCompatQueuesGetMember' => sub {
    subtest 'test_returns_member_resource' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->queues->get_member('QU_GM', 'CA_GM');
        is(ref $result, 'HASH', 'expected hashref');
        # Member resources expose call_sid + queue_sid + position.
        ok(exists $result->{call_sid} || exists $result->{queue_sid},
            'has call_sid or queue_sid');
    };

    subtest 'test_journal_records_get_to_specific_member' => sub {
        my $client = MockTest::client();
        $client->compat->queues->get_member('QU_GMX', 'CA_GMX');
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path}, "$BASE/QU_GMX/Members/CA_GMX", 'path matches');
    };
};

subtest 'TestCompatQueuesDequeueMember' => sub {
    subtest 'test_returns_member_resource' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->queues->dequeue_member(
            'QU_DM', 'CA_DM', Url => 'https://a.b',
        );
        is(ref $result, 'HASH', 'expected hashref');
        ok(exists $result->{call_sid} || exists $result->{queue_sid},
            'has call_sid or queue_sid');
    };

    subtest 'test_journal_records_post_with_url' => sub {
        my $client = MockTest::client();
        $client->compat->queues->dequeue_member(
            'QU_DMX', 'CA_DMX',
            Url    => 'https://a.b/url',
            Method => 'POST',
        );
        my $j = MockTest::journal_last();
        is($j->{method}, 'POST', 'POST recorded');
        is($j->{path}, "$BASE/QU_DMX/Members/CA_DMX", 'path matches');
        is(ref $j->{body}, 'HASH', 'body is hashref');
        is($j->{body}{Url}, 'https://a.b/url', 'Url forwarded');
        is($j->{body}{Method}, 'POST', 'Method forwarded');
    };
};

done_testing();
