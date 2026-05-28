#!/usr/bin/env perl
# Mock-backed unit tests translated from
# signalwire-python/tests/unit/rest/test_compat_conferences.py.
#
# Covers the full Conferences surface: list/get/update on the conference
# itself, plus participant, recording, and stream sub-resources. Drives
# client->compat->conferences->* against the live mock server and asserts
# on both the parsed body and the journal entry.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use MockTest;

my $BASE = '/api/laml/2010-04-01/Accounts/test_proj/Conferences';

# ---- Conference itself ---------------------------------------------------

subtest 'TestCompatConferencesList' => sub {
    subtest 'test_returns_paginated_list' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->conferences->list();
        is(ref $result, 'HASH', 'expected hashref');
        ok(exists $result->{conferences},
            "missing 'conferences' key, got " . join(',', sort keys %$result));
        is(ref $result->{conferences}, 'ARRAY', 'conferences is arrayref');
        # Compat list bodies always carry a 'page' int.
        ok(exists $result->{page}, 'page key present');
    };

    subtest 'test_journal_records_get_to_conferences' => sub {
        my $client = MockTest::client();
        $client->compat->conferences->list();
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path}, $BASE, 'path is conferences collection');
        isnt($j->{matched_route}, undef, 'matched_route set');
    };
};

subtest 'TestCompatConferencesGet' => sub {
    subtest 'test_returns_conference_resource' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->conferences->get('CF_TEST');
        is(ref $result, 'HASH', 'expected hashref');
        # Conference resources carry friendly_name + status.
        ok(exists $result->{friendly_name} || exists $result->{status},
            'has friendly_name or status');
    };

    subtest 'test_journal_records_get_with_sid' => sub {
        my $client = MockTest::client();
        $client->compat->conferences->get('CF_GETSID');
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path}, "$BASE/CF_GETSID", 'path includes sid');
    };
};

subtest 'TestCompatConferencesUpdate' => sub {
    subtest 'test_returns_updated_conference' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->conferences->update(
            'CF_X', Status => 'completed',
        );
        is(ref $result, 'HASH', 'expected hashref');
        ok(exists $result->{friendly_name} || exists $result->{status},
            'has friendly_name or status');
    };

    subtest 'test_journal_records_post_with_status' => sub {
        my $client = MockTest::client();
        $client->compat->conferences->update(
            'CF_UPD',
            Status      => 'completed',
            AnnounceUrl => 'https://a.b',
        );
        my $j = MockTest::journal_last();
        is($j->{method}, 'POST', 'POST recorded');
        is($j->{path}, "$BASE/CF_UPD", 'path includes sid');
        is(ref $j->{body}, 'HASH', 'body is hashref');
        is($j->{body}{Status}, 'completed', 'Status forwarded');
        is($j->{body}{AnnounceUrl}, 'https://a.b', 'AnnounceUrl forwarded');
    };
};

# ---- Participants --------------------------------------------------------

subtest 'TestCompatConferencesGetParticipant' => sub {
    subtest 'test_returns_participant' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->conferences->get_participant('CF_P', 'CA_P');
        is(ref $result, 'HASH', 'expected hashref');
        ok(exists $result->{call_sid} || exists $result->{conference_sid},
            'has call_sid or conference_sid');
    };

    subtest 'test_journal_records_get_to_participant' => sub {
        my $client = MockTest::client();
        $client->compat->conferences->get_participant('CF_GP', 'CA_GP');
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path}, "$BASE/CF_GP/Participants/CA_GP", 'path matches');
    };
};

subtest 'TestCompatConferencesUpdateParticipant' => sub {
    subtest 'test_returns_participant_resource' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->conferences->update_participant(
            'CF_UP', 'CA_UP', Muted => JSON::true,
        );
        is(ref $result, 'HASH', 'expected hashref');
        ok(exists $result->{call_sid} || exists $result->{conference_sid},
            'has call_sid or conference_sid');
    };

    subtest 'test_journal_records_post_with_mute_flag' => sub {
        my $client = MockTest::client();
        $client->compat->conferences->update_participant(
            'CF_M', 'CA_M', Muted => JSON::true, Hold => JSON::false,
        );
        my $j = MockTest::journal_last();
        is($j->{method}, 'POST', 'POST recorded');
        is($j->{path}, "$BASE/CF_M/Participants/CA_M", 'path matches');
        is(ref $j->{body}, 'HASH', 'body is hashref');
        # JSON booleans round-trip as JSON::PP::Boolean / JSON::true objects.
        ok(!!$j->{body}{Muted}, 'Muted forwarded as truthy');
        ok(!$j->{body}{Hold}, 'Hold forwarded as falsey');
    };
};

subtest 'TestCompatConferencesRemoveParticipant' => sub {
    subtest 'test_returns_empty_or_object' => sub {
        my $client = MockTest::client();
        # 204-style deletes return {} from the SDK; a synthesized response
        # may also return a body. Either is acceptable.
        my $result = $client->compat->conferences->remove_participant('CF_R', 'CA_R');
        is(ref $result, 'HASH', 'remove_participant returns hashref');
    };

    subtest 'test_journal_records_delete_call' => sub {
        my $client = MockTest::client();
        $client->compat->conferences->remove_participant('CF_RM', 'CA_RM');
        my $j = MockTest::journal_last();
        is($j->{method}, 'DELETE', 'DELETE recorded');
        is($j->{path}, "$BASE/CF_RM/Participants/CA_RM", 'path matches');
    };
};

# ---- Recordings ----------------------------------------------------------

subtest 'TestCompatConferencesListRecordings' => sub {
    subtest 'test_returns_paginated_recordings' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->conferences->list_recordings('CF_LR');
        is(ref $result, 'HASH', 'expected hashref');
        ok(exists $result->{recordings},
            "missing 'recordings' key, got " . join(',', sort keys %$result));
        is(ref $result->{recordings}, 'ARRAY', 'recordings is arrayref');
    };

    subtest 'test_journal_records_get_recordings' => sub {
        my $client = MockTest::client();
        $client->compat->conferences->list_recordings('CF_LRX');
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path}, "$BASE/CF_LRX/Recordings", 'path matches');
    };
};

subtest 'TestCompatConferencesGetRecording' => sub {
    subtest 'test_returns_recording_resource' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->conferences->get_recording('CF_GR', 'RE_GR');
        is(ref $result, 'HASH', 'expected hashref');
        # Recording resources carry call_sid plus channel/status.
        ok(exists $result->{sid} || exists $result->{call_sid},
            'has sid or call_sid');
    };

    subtest 'test_journal_records_get_recording' => sub {
        my $client = MockTest::client();
        $client->compat->conferences->get_recording('CF_GRX', 'RE_GRX');
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path}, "$BASE/CF_GRX/Recordings/RE_GRX", 'path matches');
    };
};

subtest 'TestCompatConferencesUpdateRecording' => sub {
    subtest 'test_returns_recording_resource' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->conferences->update_recording(
            'CF_URC', 'RE_URC', Status => 'paused',
        );
        is(ref $result, 'HASH', 'expected hashref');
        ok(exists $result->{sid} || exists $result->{status},
            'has sid or status');
    };

    subtest 'test_journal_records_post_with_status' => sub {
        my $client = MockTest::client();
        $client->compat->conferences->update_recording(
            'CF_UR', 'RE_UR', Status => 'paused',
        );
        my $j = MockTest::journal_last();
        is($j->{method}, 'POST', 'POST recorded');
        is($j->{path}, "$BASE/CF_UR/Recordings/RE_UR", 'path matches');
        is(ref $j->{body}, 'HASH', 'body is hashref');
        is($j->{body}{Status}, 'paused', 'Status forwarded');
    };
};

subtest 'TestCompatConferencesDeleteRecording' => sub {
    subtest 'test_no_exception_on_delete' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->conferences->delete_recording('CF_DR', 'RE_DR');
        is(ref $result, 'HASH', 'delete returns hashref');
    };

    subtest 'test_journal_records_delete' => sub {
        my $client = MockTest::client();
        $client->compat->conferences->delete_recording('CF_DRX', 'RE_DRX');
        my $j = MockTest::journal_last();
        is($j->{method}, 'DELETE', 'DELETE recorded');
        is($j->{path}, "$BASE/CF_DRX/Recordings/RE_DRX", 'path matches');
    };
};

# ---- Streams -------------------------------------------------------------

subtest 'TestCompatConferencesStartStream' => sub {
    subtest 'test_returns_stream_resource' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->conferences->start_stream(
            'CF_SS', Url => 'wss://a.b/s',
        );
        is(ref $result, 'HASH', 'expected hashref');
        ok(exists $result->{sid} || exists $result->{name},
            'has sid or name');
    };

    subtest 'test_journal_records_post_to_streams' => sub {
        my $client = MockTest::client();
        $client->compat->conferences->start_stream(
            'CF_SSX', Url => 'wss://a.b/s', Name => 'strm',
        );
        my $j = MockTest::journal_last();
        is($j->{method}, 'POST', 'POST recorded');
        is($j->{path}, "$BASE/CF_SSX/Streams", 'path matches');
        is(ref $j->{body}, 'HASH', 'body is hashref');
        is($j->{body}{Url}, 'wss://a.b/s', 'Url forwarded');
    };
};

subtest 'TestCompatConferencesStopStream' => sub {
    subtest 'test_returns_stream_resource' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->conferences->stop_stream(
            'CF_TS', 'ST_TS', Status => 'stopped',
        );
        is(ref $result, 'HASH', 'expected hashref');
        ok(exists $result->{sid} || exists $result->{status},
            'has sid or status');
    };

    subtest 'test_journal_records_post_to_specific_stream' => sub {
        my $client = MockTest::client();
        $client->compat->conferences->stop_stream(
            'CF_TSX', 'ST_TSX', Status => 'stopped',
        );
        my $j = MockTest::journal_last();
        is($j->{method}, 'POST', 'POST recorded');
        is($j->{path}, "$BASE/CF_TSX/Streams/ST_TSX", 'path matches');
        is(ref $j->{body}, 'HASH', 'body is hashref');
        is($j->{body}{Status}, 'stopped', 'Status forwarded');
    };
};

done_testing();
