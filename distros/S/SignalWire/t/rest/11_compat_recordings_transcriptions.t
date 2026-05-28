#!/usr/bin/env perl
# Mock-backed unit tests translated from
# signalwire-python/tests/unit/rest/test_compat_recordings_transcriptions.py.
#
# Both compat resources expose the same surface (list / get / delete) and
# use the account-scoped LAML path:
#   - CompatRecordings:    list, get, delete
#   - CompatTranscriptions: list, get, delete

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use MockTest;

my $BASE = '/api/laml/2010-04-01/Accounts/test_proj';

# ---- Recordings ----------------------------------------------------------

subtest 'TestCompatRecordingsList' => sub {
    subtest 'test_returns_paginated_recordings' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->recordings->list();
        is(ref $result, 'HASH', 'expected hashref');
        ok(exists $result->{recordings},
            "missing 'recordings' key, got " . join(',', sort keys %$result));
        is(ref $result->{recordings}, 'ARRAY', 'recordings is arrayref');
    };

    subtest 'test_journal_records_get' => sub {
        my $client = MockTest::client();
        $client->compat->recordings->list();
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path}, "$BASE/Recordings", 'path matches');
    };
};

subtest 'TestCompatRecordingsGet' => sub {
    subtest 'test_returns_recording_resource' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->recordings->get('RE_TEST');
        is(ref $result, 'HASH', 'expected hashref');
        # Recording resources carry call_sid + duration + sid.
        ok(exists $result->{sid} || exists $result->{call_sid},
            'has sid or call_sid');
    };

    subtest 'test_journal_records_get_with_sid' => sub {
        my $client = MockTest::client();
        $client->compat->recordings->get('RE_GET');
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path}, "$BASE/Recordings/RE_GET", 'path matches');
    };
};

subtest 'TestCompatRecordingsDelete' => sub {
    subtest 'test_no_exception_on_delete' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->recordings->delete('RE_D');
        is(ref $result, 'HASH', 'delete returns hashref');
    };

    subtest 'test_journal_records_delete' => sub {
        my $client = MockTest::client();
        $client->compat->recordings->delete('RE_DEL');
        my $j = MockTest::journal_last();
        is($j->{method}, 'DELETE', 'DELETE recorded');
        is($j->{path}, "$BASE/Recordings/RE_DEL", 'path matches');
    };
};

# ---- Transcriptions ------------------------------------------------------

subtest 'TestCompatTranscriptionsList' => sub {
    subtest 'test_returns_paginated_transcriptions' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->transcriptions->list();
        is(ref $result, 'HASH', 'expected hashref');
        ok(exists $result->{transcriptions},
            "missing 'transcriptions' key, got " . join(',', sort keys %$result));
        is(ref $result->{transcriptions}, 'ARRAY', 'transcriptions is arrayref');
    };

    subtest 'test_journal_records_get' => sub {
        my $client = MockTest::client();
        $client->compat->transcriptions->list();
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path}, "$BASE/Transcriptions", 'path matches');
    };
};

subtest 'TestCompatTranscriptionsGet' => sub {
    subtest 'test_returns_transcription_resource' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->transcriptions->get('TR_TEST');
        is(ref $result, 'HASH', 'expected hashref');
        # Transcription resources carry duration + transcription_text + sid.
        ok(exists $result->{sid} || exists $result->{duration},
            'has sid or duration');
    };

    subtest 'test_journal_records_get_with_sid' => sub {
        my $client = MockTest::client();
        $client->compat->transcriptions->get('TR_GET');
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path}, "$BASE/Transcriptions/TR_GET", 'path matches');
    };
};

subtest 'TestCompatTranscriptionsDelete' => sub {
    subtest 'test_no_exception_on_delete' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->transcriptions->delete('TR_D');
        is(ref $result, 'HASH', 'delete returns hashref');
    };

    subtest 'test_journal_records_delete' => sub {
        my $client = MockTest::client();
        $client->compat->transcriptions->delete('TR_DEL');
        my $j = MockTest::journal_last();
        is($j->{method}, 'DELETE', 'DELETE recorded');
        is($j->{path}, "$BASE/Transcriptions/TR_DEL", 'path matches');
    };
};

done_testing();
