#!/usr/bin/env perl
# Mock-backed unit tests translated from
# signalwire-python/tests/unit/rest/test_video_mock.py.
#
# Exercises the Video API surface: rooms streams, room_sessions,
# room_recordings, conferences sub-collections (tokens / streams),
# conference_tokens, and individual stream lifecycle.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use MockTest;

# ---- Rooms / streams sub-resource ---------------------------------------

subtest 'TestVideoRoomsStreams' => sub {
    subtest 'test_list_streams_returns_data_collection' => sub {
        my $client = MockTest::client();
        my $body = $client->video->rooms->list_streams('room-1');
        is(ref $body, 'HASH', 'expected hashref');
        ok(exists $body->{data},
            "missing 'data' in body keys: " . join(',', sort keys %$body));
        is(ref $body->{data}, 'ARRAY', 'data is arrayref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'GET', 'GET recorded');
        is($last->{path}, '/api/video/rooms/room-1/streams', 'path matches');
        isnt($last->{matched_route}, undef, 'matched_route set');
    };

    subtest 'test_create_stream_posts_kwargs_in_body' => sub {
        my $client = MockTest::client();
        my $body = $client->video->rooms->create_stream(
            'room-1', url => 'rtmp://example.com/live',
        );
        is(ref $body, 'HASH', 'expected hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'POST', 'POST recorded');
        is($last->{path}, '/api/video/rooms/room-1/streams', 'path matches');
        is(ref $last->{body}, 'HASH', 'body is hashref');
        is($last->{body}{url}, 'rtmp://example.com/live', 'url forwarded');
    };
};

# ---- Room Sessions ------------------------------------------------------

subtest 'TestVideoRoomSessions' => sub {
    subtest 'test_list_returns_data_collection' => sub {
        my $client = MockTest::client();
        my $body = $client->video->room_sessions->list();
        is(ref $body, 'HASH', 'expected hashref');
        ok(exists $body->{data},
            "missing 'data' in body keys: " . join(',', sort keys %$body));
        is(ref $body->{data}, 'ARRAY', 'data is arrayref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'GET', 'GET recorded');
        is($last->{path}, '/api/video/room_sessions', 'path matches');
    };

    subtest 'test_get_returns_session_object' => sub {
        my $client = MockTest::client();
        my $body = $client->video->room_sessions->get('sess-abc');
        is(ref $body, 'HASH', 'expected hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'GET', 'GET recorded');
        is($last->{path}, '/api/video/room_sessions/sess-abc', 'path matches');
        isnt($last->{matched_route}, undef, 'matched_route set');
    };

    subtest 'test_list_events_uses_events_subpath' => sub {
        my $client = MockTest::client();
        my $body = $client->video->room_sessions->list_events('sess-1');
        is(ref $body, 'HASH', 'expected hashref');
        ok(exists $body->{data} && ref $body->{data} eq 'ARRAY', 'has data array');

        my $last = MockTest::journal_last();
        is($last->{method}, 'GET', 'GET recorded');
        is($last->{path}, '/api/video/room_sessions/sess-1/events', 'path matches');
    };

    subtest 'test_list_recordings_uses_recordings_subpath' => sub {
        my $client = MockTest::client();
        my $body = $client->video->room_sessions->list_recordings('sess-2');
        is(ref $body, 'HASH', 'expected hashref');
        ok(exists $body->{data}, 'has data key');

        my $last = MockTest::journal_last();
        is($last->{method}, 'GET', 'GET recorded');
        is($last->{path}, '/api/video/room_sessions/sess-2/recordings', 'path matches');
    };
};

# ---- Room Recordings ----------------------------------------------------

subtest 'TestVideoRoomRecordings' => sub {
    subtest 'test_list_returns_data_collection' => sub {
        my $client = MockTest::client();
        my $body = $client->video->room_recordings->list();
        is(ref $body, 'HASH', 'expected hashref');
        ok(exists $body->{data} && ref $body->{data} eq 'ARRAY',
            'data is arrayref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'GET', 'GET recorded');
        is($last->{path}, '/api/video/room_recordings', 'path matches');
    };

    subtest 'test_get_returns_single_recording' => sub {
        my $client = MockTest::client();
        my $body = $client->video->room_recordings->get('rec-xyz');
        is(ref $body, 'HASH', 'expected hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'GET', 'GET recorded');
        is($last->{path}, '/api/video/room_recordings/rec-xyz', 'path matches');
    };

    subtest 'test_delete_returns_empty_dict_for_204' => sub {
        my $client = MockTest::client();
        # The mock synthesises 204/empty for DELETE which the SDK turns
        # into {}.
        my $body = $client->video->room_recordings->delete('rec-del');
        is(ref $body, 'HASH', 'delete returns hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'DELETE', 'DELETE recorded');
        is($last->{path}, '/api/video/room_recordings/rec-del', 'path matches');
        isnt($last->{matched_route}, undef, 'matched_route set');
    };

    subtest 'test_list_events_uses_events_subpath' => sub {
        my $client = MockTest::client();
        my $body = $client->video->room_recordings->list_events('rec-1');
        is(ref $body, 'HASH', 'expected hashref');
        ok(exists $body->{data}, 'has data key');

        my $last = MockTest::journal_last();
        is($last->{method}, 'GET', 'GET recorded');
        is($last->{path}, '/api/video/room_recordings/rec-1/events', 'path matches');
    };
};

# ---- Conferences sub-collections (tokens, streams) -----------------------

subtest 'TestVideoConferences' => sub {
    subtest 'test_list_conference_tokens' => sub {
        my $client = MockTest::client();
        my $body = $client->video->conferences->list_conference_tokens('conf-1');
        is(ref $body, 'HASH', 'expected hashref');
        ok(exists $body->{data} && ref $body->{data} eq 'ARRAY',
            'data is arrayref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'GET', 'GET recorded');
        is($last->{path}, '/api/video/conferences/conf-1/conference_tokens',
            'path matches');
    };

    subtest 'test_list_streams' => sub {
        my $client = MockTest::client();
        my $body = $client->video->conferences->list_streams('conf-2');
        is(ref $body, 'HASH', 'expected hashref');
        ok(exists $body->{data} && ref $body->{data} eq 'ARRAY',
            'data is arrayref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'GET', 'GET recorded');
        is($last->{path}, '/api/video/conferences/conf-2/streams', 'path matches');
    };
};

# ---- Conference Tokens (top-level) --------------------------------------

subtest 'TestVideoConferenceTokens' => sub {
    subtest 'test_get_returns_single_token' => sub {
        my $client = MockTest::client();
        my $body = $client->video->conference_tokens->get('tok-1');
        is(ref $body, 'HASH', 'expected hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'GET', 'GET recorded');
        is($last->{path}, '/api/video/conference_tokens/tok-1', 'path matches');
        isnt($last->{matched_route}, undef, 'matched_route set');
    };

    subtest 'test_reset_posts_to_reset_subpath' => sub {
        my $client = MockTest::client();
        my $body = $client->video->conference_tokens->reset('tok-2');
        is(ref $body, 'HASH', 'expected hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'POST', 'POST recorded');
        is($last->{path}, '/api/video/conference_tokens/tok-2/reset',
            'path matches');
        # reset is a no-body POST.
        ok(!defined $last->{body}
              || (ref $last->{body} eq 'HASH' && !%{ $last->{body} })
              || $last->{body} eq '',
            'body is empty');
    };
};

# ---- Streams (top-level) ------------------------------------------------

subtest 'TestVideoStreams' => sub {
    subtest 'test_get_returns_stream_resource' => sub {
        my $client = MockTest::client();
        my $body = $client->video->streams->get('stream-1');
        is(ref $body, 'HASH', 'expected hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'GET', 'GET recorded');
        is($last->{path}, '/api/video/streams/stream-1', 'path matches');
    };

    subtest 'test_update_uses_put_with_kwargs' => sub {
        my $client = MockTest::client();
        # VideoStreams.update calls _http->put(path, body=kwargs).
        my $body = $client->video->streams->update(
            'stream-2', url => 'rtmp://example.com/new',
        );
        is(ref $body, 'HASH', 'expected hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'PUT', 'PUT recorded');
        is($last->{path}, '/api/video/streams/stream-2', 'path matches');
        is(ref $last->{body}, 'HASH', 'body is hashref');
        is($last->{body}{url}, 'rtmp://example.com/new', 'url forwarded');
    };

    subtest 'test_delete' => sub {
        my $client = MockTest::client();
        my $body = $client->video->streams->delete('stream-3');
        is(ref $body, 'HASH', 'delete returns hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'DELETE', 'DELETE recorded');
        is($last->{path}, '/api/video/streams/stream-3', 'path matches');
        isnt($last->{matched_route}, undef, 'matched_route set');
    };
};

done_testing();
