#!/usr/bin/env perl
# Mock-backed unit tests translated from
# signalwire-python/tests/unit/rest/test_compat_calls_streams.py.
#
# Covers the gap entries for CompatCalls that aren't already exercised by
# test_namespaces.py: start_stream, stop_stream, update_recording.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use MockTest;

subtest 'TestCompatCallsStartStream' => sub {
    subtest 'returns_stream_resource' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->calls->start_stream(
            'CA_TEST',
            Url  => 'wss://example.com/stream',
            Name => 'my-stream',
        );
        is(ref $result, 'HASH', 'response is a hashref');
        ok(exists $result->{sid} || exists $result->{name},
            "stream resource has sid or name (got keys: " . join(',', sort keys %$result) . ")");
    };

    subtest 'journal_records_post_to_streams_collection' => sub {
        my $client = MockTest::client();
        $client->compat->calls->start_stream(
            'CA_JX1', Url => 'wss://a.b/s', Name => 'strm-x',
        );
        my $j = MockTest::journal_last();
        is($j->{method}, 'POST', 'POST recorded');
        is($j->{path},
           '/api/laml/2010-04-01/Accounts/test_proj/Calls/CA_JX1/Streams',
           'path is /Calls/{sid}/Streams');
        is(ref $j->{body}, 'HASH', 'body decoded as hashref');
        is($j->{body}{Url},  'wss://a.b/s', 'body Url forwarded');
        is($j->{body}{Name}, 'strm-x',     'body Name forwarded');
    };
};

subtest 'TestCompatCallsStopStream' => sub {
    subtest 'returns_stream_resource_with_status' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->calls->stop_stream(
            'CA_T1', 'ST_T1', Status => 'stopped',
        );
        is(ref $result, 'HASH', 'response is a hashref');
        ok(exists $result->{sid} || exists $result->{status},
            'stream stop response has sid or status');
    };

    subtest 'journal_records_post_to_specific_stream' => sub {
        my $client = MockTest::client();
        $client->compat->calls->stop_stream('CA_S1', 'ST_S1', Status => 'stopped');
        my $j = MockTest::journal_last();
        is($j->{method}, 'POST', 'POST recorded');
        is($j->{path},
           '/api/laml/2010-04-01/Accounts/test_proj/Calls/CA_S1/Streams/ST_S1',
           'path is /Streams/{stream_sid}');
        is(ref $j->{body}, 'HASH', 'body decoded as hashref');
        is($j->{body}{Status}, 'stopped', 'body Status forwarded');
    };
};

subtest 'TestCompatCallsUpdateRecording' => sub {
    subtest 'returns_recording_resource' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->calls->update_recording(
            'CA_T2', 'RE_T2', Status => 'paused',
        );
        is(ref $result, 'HASH', 'response is a hashref');
        ok(exists $result->{sid} || exists $result->{status},
            'recording resource has sid or status');
    };

    subtest 'journal_records_post_to_specific_recording' => sub {
        my $client = MockTest::client();
        $client->compat->calls->update_recording(
            'CA_R1', 'RE_R1', Status => 'paused',
        );
        my $j = MockTest::journal_last();
        is($j->{method}, 'POST', 'POST recorded');
        is($j->{path},
           '/api/laml/2010-04-01/Accounts/test_proj/Calls/CA_R1/Recordings/RE_R1',
           'path is /Recordings/{recording_sid}');
        is(ref $j->{body}, 'HASH', 'body decoded as hashref');
        is($j->{body}{Status}, 'paused', 'body Status forwarded');
    };
};

done_testing();
