#!/usr/bin/env perl
# Mock-backed unit tests translated from
# signalwire-python/tests/unit/rest/test_logs_mock.py.
#
# The Logs namespace fans out across four spec docs (message/voice/fax/
# logs.conferences) because each kind of log lives at a different
# sub-API. Each sub-resource has a small surface (list, get, optional
# list_events).

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use MockTest;

# ---- Message Logs --------------------------------------------------------

subtest 'TestMessageLogs' => sub {
    subtest 'test_list_returns_dict' => sub {
        my $client = MockTest::client();
        my $body = $client->logs->messages->list();
        is(ref $body, 'HASH', 'expected hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'GET', 'GET recorded');
        is($last->{path}, '/api/messaging/logs', 'path matches');
        is($last->{matched_route}, 'message.list_message_logs',
            'matched route is message.list_message_logs');
    };

    subtest 'test_get_uses_id_in_path' => sub {
        my $client = MockTest::client();
        my $body = $client->logs->messages->get('ml-42');
        is(ref $body, 'HASH', 'expected hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'GET', 'GET recorded');
        is($last->{path}, '/api/messaging/logs/ml-42', 'path matches');
        isnt($last->{matched_route}, undef, 'matched_route set');
    };
};

# ---- Voice Logs ----------------------------------------------------------

subtest 'TestVoiceLogs' => sub {
    subtest 'test_list_returns_dict' => sub {
        my $client = MockTest::client();
        my $body = $client->logs->voice->list();
        is(ref $body, 'HASH', 'expected hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'GET', 'GET recorded');
        is($last->{path}, '/api/voice/logs', 'path matches');
        is($last->{matched_route}, 'voice.list_voice_logs',
            'matched route is voice.list_voice_logs');
    };

    subtest 'test_get_uses_id_in_path' => sub {
        my $client = MockTest::client();
        my $body = $client->logs->voice->get('vl-99');
        is(ref $body, 'HASH', 'expected hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'GET', 'GET recorded');
        is($last->{path}, '/api/voice/logs/vl-99', 'path matches');
    };
};

# ---- Fax Logs ------------------------------------------------------------

subtest 'TestFaxLogs' => sub {
    subtest 'test_list_returns_dict' => sub {
        my $client = MockTest::client();
        my $body = $client->logs->fax->list();
        is(ref $body, 'HASH', 'expected hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'GET', 'GET recorded');
        is($last->{path}, '/api/fax/logs', 'path matches');
        is($last->{matched_route}, 'fax.list_fax_logs',
            'matched route is fax.list_fax_logs');
    };

    subtest 'test_get_uses_id_in_path' => sub {
        my $client = MockTest::client();
        my $body = $client->logs->fax->get('fl-7');
        is(ref $body, 'HASH', 'expected hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'GET', 'GET recorded');
        is($last->{path}, '/api/fax/logs/fl-7', 'path matches');
    };
};

# ---- Conference Logs -----------------------------------------------------

subtest 'TestConferenceLogs' => sub {
    subtest 'test_list_returns_dict' => sub {
        my $client = MockTest::client();
        my $body = $client->logs->conferences->list();
        is(ref $body, 'HASH', 'expected hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'GET', 'GET recorded');
        # The conferences logs spec lives under /api/logs/conferences.
        is($last->{path}, '/api/logs/conferences', 'path matches');
        is($last->{matched_route}, 'logs.list_conferences',
            'matched route is logs.list_conferences');
    };
};

done_testing();
