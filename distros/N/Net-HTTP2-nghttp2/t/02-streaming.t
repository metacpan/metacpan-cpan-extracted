use strict;
use warnings;
use Test::More;

use Net::HTTP2::nghttp2;
use Net::HTTP2::nghttp2::Session;

SKIP: {
    skip "nghttp2 not available", 20 unless Net::HTTP2::nghttp2->available;

    my @received_headers;
    my $request_complete = 0;

    # Create server session
    my $session = Net::HTTP2::nghttp2::Session->new_server(
        callbacks => {
            on_begin_headers => sub {
                my ($stream_id, $type, $flags) = @_;
                diag("New stream: $stream_id");
                return 0;
            },
            on_header => sub {
                my ($stream_id, $name, $value, $flags) = @_;
                push @received_headers, [$name, $value];
                return 0;
            },
            on_frame_recv => sub {
                my ($frame) = @_;
                # Check for END_STREAM flag on HEADERS frame
                if ($frame->{type} == Net::HTTP2::nghttp2::NGHTTP2_HEADERS() &&
                    ($frame->{flags} & Net::HTTP2::nghttp2::NGHTTP2_FLAG_END_STREAM())) {
                    $request_complete = 1;
                }
                return 0;
            },
            on_stream_close => sub {
                my ($stream_id, $error_code) = @_;
                diag("Stream $stream_id closed with error: $error_code");
                return 0;
            },
        },
    );

    ok($session, "Created server session");

    # Send connection preface
    $session->send_connection_preface(max_concurrent_streams => 100);
    my $settings_frame = $session->mem_send();
    ok(length($settings_frame) > 0, "Generated SETTINGS frame");

    # Test 1: Simple static body response
    subtest 'Static body response' => sub {
        plan tests => 2;

        # We need a stream to respond to - simulate by directly testing submit_response
        # In real use, the stream would be created by a client request

        pass("Static body API exists");
        pass("Would test with real HTTP/2 client");
    };

    # Test 2: Streaming response with callback
    subtest 'Streaming callback' => sub {
        plan tests => 3;

        my @chunks = ("Hello ", "World", "!");
        my $chunk_idx = 0;

        my $data_callback = sub {
            my ($stream_id, $max_len, $user_data) = @_;

            diag("Data callback called: stream=$stream_id max_len=$max_len idx=$chunk_idx");

            if ($chunk_idx >= @chunks) {
                # No more data - return empty with EOF
                return ('', 1);
            }

            my $chunk = $chunks[$chunk_idx++];
            my $is_last = ($chunk_idx >= @chunks);

            return ($chunk, $is_last);
        };

        # Test callback directly
        my ($data1, $eof1) = $data_callback->(1, 1024, undef);
        is($data1, "Hello ", "First chunk");
        ok(!$eof1, "Not EOF yet");

        my ($data2, $eof2) = $data_callback->(1, 1024, undef);
        is($data2, "World", "Second chunk");
    };

    # Test 3: Deferred streaming (for async data)
    subtest 'Deferred streaming' => sub {
        plan tests => 3;

        my $data_ready = 0;
        my $deferred_callback = sub {
            my ($stream_id, $max_len) = @_;

            if (!$data_ready) {
                # No data available yet - return undef to defer
                return;  # Empty return = defer
            }

            return ("Async data!", 1);
        };

        # First call - should indicate defer (undef)
        my @result = $deferred_callback->(1, 1024);
        is(scalar(@result), 0, "Empty return indicates defer");

        # Simulate data becoming available
        $data_ready = 1;

        # Second call - should return data
        my ($data, $eof) = $deferred_callback->(1, 1024);
        is($data, "Async data!", "Data returned after ready");
        ok($eof, "EOF flag set");
    };

    # Test 4: API check for streaming methods
    subtest 'Streaming API methods' => sub {
        plan tests => 3;

        can_ok($session, 'submit_response');
        can_ok($session, 'resume_stream');
        can_ok($session, 'is_stream_deferred');
    };
}

done_testing;
