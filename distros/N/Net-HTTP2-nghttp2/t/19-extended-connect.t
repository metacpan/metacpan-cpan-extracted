#!/usr/bin/env perl
# Tests for RFC 8441 - Bootstrapping WebSockets with HTTP/2
# Extended CONNECT protocol support

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Net::HTTP2::nghttp2;
use Net::HTTP2::nghttp2::Session;
use Test::HTTP2::Frame qw(:all);
use Test::HTTP2::HPACK qw(encode_headers);

SKIP: {
    skip "nghttp2 not available", 1 unless Net::HTTP2::nghttp2->available;

    #==========================================================================
    # Test: NGHTTP2_SETTINGS_ENABLE_CONNECT_PROTOCOL constant is exported
    #==========================================================================
    subtest 'SETTINGS_ENABLE_CONNECT_PROTOCOL constant exported' => sub {
        # Test that the constant is exported and has the correct value
        can_ok('Net::HTTP2::nghttp2', 'NGHTTP2_SETTINGS_ENABLE_CONNECT_PROTOCOL');
        is(Net::HTTP2::nghttp2::NGHTTP2_SETTINGS_ENABLE_CONNECT_PROTOCOL(), 0x8,
           "NGHTTP2_SETTINGS_ENABLE_CONNECT_PROTOCOL has correct value (0x8)");

        # Test that it's in the exports
        my @exports = @Net::HTTP2::nghttp2::EXPORT_OK;
        ok(grep({ $_ eq 'NGHTTP2_SETTINGS_ENABLE_CONNECT_PROTOCOL' } @exports),
           "Constant is in \@EXPORT_OK");

        done_testing;
    };

    #==========================================================================
    # Test: Server sends ENABLE_CONNECT_PROTOCOL in SETTINGS
    #==========================================================================
    subtest 'server sends enable_connect_protocol setting' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
            },
            settings => {
                enable_connect_protocol => 1,
            },
        );

        ok($session, "Created server session with enable_connect_protocol");

        # Send connection preface
        $session->send_connection_preface();
        my $preface_data = $session->mem_send();

        ok(length($preface_data) > 0, "Server sent connection preface");

        # Parse the SETTINGS frame from preface
        my @frames = parse_frames_with_settings($preface_data);
        my @settings_frames = grep { $_->{type} == FRAME_SETTINGS } @frames;

        ok(@settings_frames >= 1, "Found SETTINGS frame in preface");

        # Check for ENABLE_CONNECT_PROTOCOL setting
        my $settings_frame = $settings_frames[0];
        my $found_setting = 0;

        for my $setting (@{$settings_frame->{settings} // []}) {
            if ($setting->{id} == SETTINGS_ENABLE_CONNECT_PROTOCOL) {
                $found_setting = 1;
                is($setting->{value}, 1, "ENABLE_CONNECT_PROTOCOL value is 1");
                last;
            }
        }

        ok($found_setting, "ENABLE_CONNECT_PROTOCOL setting found in SETTINGS frame");

        done_testing;
    };

    #==========================================================================
    # Test: Server without enable_connect_protocol doesn't send the setting
    #==========================================================================
    subtest 'server without enable_connect_protocol' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
            },
            # No enable_connect_protocol setting
        );

        ok($session, "Created server session without enable_connect_protocol");

        $session->send_connection_preface();
        my $preface_data = $session->mem_send();

        my @frames = parse_frames_with_settings($preface_data);
        my @settings_frames = grep { $_->{type} == FRAME_SETTINGS } @frames;

        ok(@settings_frames >= 1, "Found SETTINGS frame");

        # Verify ENABLE_CONNECT_PROTOCOL is NOT present
        my $settings_frame = $settings_frames[0];
        my $found_setting = 0;

        for my $setting (@{$settings_frame->{settings} // []}) {
            if ($setting->{id} == SETTINGS_ENABLE_CONNECT_PROTOCOL) {
                $found_setting = 1;
                last;
            }
        }

        ok(!$found_setting, "ENABLE_CONNECT_PROTOCOL not present when not enabled");

        done_testing;
    };

    #==========================================================================
    # Test: Server receives extended CONNECT request with :protocol header
    #==========================================================================
    subtest 'server receives extended CONNECT with :protocol header' => sub {
        my @headers_received;
        my @frames_received;

        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header => sub {
                    my ($stream_id, $name, $value, $flags) = @_;
                    push @headers_received, [$stream_id, $name, $value];
                    return 0;
                },
                on_frame_recv => sub {
                    my ($frame) = @_;
                    push @frames_received, $frame;
                    return 0;
                },
            },
            settings => {
                enable_connect_protocol => 1,
            },
        );

        ok($session, "Created server session");

        # Send server preface
        $session->send_connection_preface();
        $session->mem_send();

        # Client sends preface and SETTINGS
        my $client_data = CLIENT_PREFACE . build_settings_frame();
        $session->mem_recv($client_data);

        # Client sends extended CONNECT request (RFC 8441)
        # Extended CONNECT has: :method CONNECT, :protocol websocket, :path, :scheme, :authority
        my $headers = encode_headers([
            [':method', 'CONNECT'],
            [':protocol', 'websocket'],
            [':scheme', 'https'],
            [':authority', 'example.com'],
            [':path', '/chat'],
            ['sec-websocket-version', '13'],
            ['sec-websocket-key', 'dGhlIHNhbXBsZSBub25jZQ=='],
        ]);

        my $headers_frame = build_headers_frame(
            stream_id    => 1,
            header_block => $headers,
            end_stream   => 0,  # WebSocket keeps stream open
            end_headers  => 1,
        );

        $session->mem_recv($headers_frame);

        # Verify we received all headers including :protocol
        my %received = map { $_->[1] => $_->[2] } @headers_received;

        is($received{':method'}, 'CONNECT', "Received :method CONNECT");
        is($received{':protocol'}, 'websocket', "Received :protocol websocket");
        is($received{':scheme'}, 'https', "Received :scheme");
        is($received{':authority'}, 'example.com', "Received :authority");
        is($received{':path'}, '/chat', "Received :path");

        # Verify HEADERS frame was received
        my @headers_frames = grep { $_->{type} == FRAME_HEADERS } @frames_received;
        ok(@headers_frames >= 1, "Received HEADERS frame");

        done_testing;
    };

    #==========================================================================
    # Test: Client can submit extended CONNECT request
    #==========================================================================
    subtest 'client submits extended CONNECT request' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_client(
            callbacks => {
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
                on_stream_close  => sub { return 0; },
            },
        );

        ok($session, "Created client session");

        $session->send_connection_preface();
        my $preface = $session->mem_send();
        ok(length($preface) > 0, "Client sent connection preface");

        # Simulate server sending SETTINGS with ENABLE_CONNECT_PROTOCOL
        my $server_settings = build_settings_frame(
            settings => {
                SETTINGS_ENABLE_CONNECT_PROTOCOL() => 1,
            },
        );
        $session->mem_recv($server_settings);

        # Send SETTINGS ACK
        $session->mem_send();

        # Submit extended CONNECT request
        my $stream_id = $session->submit_request(
            method    => 'CONNECT',
            path      => '/chat',
            scheme    => 'https',
            authority => 'example.com',
            headers   => [
                [':protocol', 'websocket'],
                ['sec-websocket-version', '13'],
                ['sec-websocket-key', 'dGhlIHNhbXBsZSBub25jZQ=='],
            ],
        );

        ok($stream_id > 0, "Submitted extended CONNECT request, stream_id=$stream_id");

        # Get the outgoing data
        my $request_data = $session->mem_send();
        ok(length($request_data) > 0, "Client has data to send");

        done_testing;
    };

    #==========================================================================
    # Test: Regular CONNECT vs Extended CONNECT distinction
    #==========================================================================
    subtest 'regular CONNECT vs extended CONNECT' => sub {
        my @requests;
        my $current_request;

        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub {
                    my ($stream_id) = @_;
                    $current_request = { stream_id => $stream_id, headers => {} };
                    return 0;
                },
                on_header => sub {
                    my ($stream_id, $name, $value, $flags) = @_;
                    $current_request->{headers}{$name} = $value;
                    return 0;
                },
                on_frame_recv => sub {
                    my ($frame) = @_;
                    if ($frame->{type} == FRAME_HEADERS && $current_request) {
                        push @requests, $current_request;
                        $current_request = undef;
                    }
                    return 0;
                },
            },
            settings => {
                enable_connect_protocol => 1,
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        # Client preface
        $session->mem_recv(CLIENT_PREFACE . build_settings_frame());

        # Send regular CONNECT (proxy style, no :protocol)
        my $regular_connect = encode_headers([
            [':method', 'CONNECT'],
            [':authority', 'proxy.example.com:443'],
        ]);

        $session->mem_recv(build_headers_frame(
            stream_id    => 1,
            header_block => $regular_connect,
            end_stream   => 0,
            end_headers  => 1,
        ));

        # Send extended CONNECT (RFC 8441 WebSocket)
        my $extended_connect = encode_headers([
            [':method', 'CONNECT'],
            [':protocol', 'websocket'],
            [':scheme', 'https'],
            [':authority', 'example.com'],
            [':path', '/ws'],
        ]);

        $session->mem_recv(build_headers_frame(
            stream_id    => 3,
            header_block => $extended_connect,
            end_stream   => 0,
            end_headers  => 1,
        ));

        is(scalar(@requests), 2, "Received 2 requests");

        # Regular CONNECT
        my $req1 = $requests[0];
        is($req1->{headers}{':method'}, 'CONNECT', "First is CONNECT");
        ok(!exists $req1->{headers}{':protocol'}, "Regular CONNECT has no :protocol");
        ok(!exists $req1->{headers}{':path'}, "Regular CONNECT has no :path");

        # Extended CONNECT
        my $req2 = $requests[1];
        is($req2->{headers}{':method'}, 'CONNECT', "Second is CONNECT");
        is($req2->{headers}{':protocol'}, 'websocket', "Extended CONNECT has :protocol");
        is($req2->{headers}{':path'}, '/ws', "Extended CONNECT has :path");
        is($req2->{headers}{':scheme'}, 'https', "Extended CONNECT has :scheme");

        done_testing;
    };

    #==========================================================================
    # Test: Import with :settings tag
    #==========================================================================
    subtest 'import with :settings tag' => sub {
        # Verify the constant is available through :settings tag
        my $pkg = 'ImportTest::Settings' . $$;
        eval "package $pkg; use Net::HTTP2::nghttp2 qw(:settings); 1" or die $@;

        ok($pkg->can('NGHTTP2_SETTINGS_ENABLE_CONNECT_PROTOCOL'),
           "NGHTTP2_SETTINGS_ENABLE_CONNECT_PROTOCOL exported via :settings tag");

        done_testing;
    };

}

done_testing;

# Helper to parse SETTINGS frame payload
sub parse_settings_payload {
    my ($payload) = @_;
    my @settings;

    while (length($payload) >= 6) {
        my ($id, $value) = unpack("n N", substr($payload, 0, 6, ''));
        push @settings, { id => $id, value => $value };
    }

    return \@settings;
}

# Local version of parse_frames that includes settings parsing
sub parse_frames_with_settings {
    my ($data) = @_;
    my @frames;

    while (length($data) >= 9) {
        my ($len_hi, $len_mid, $len_lo, $type, $flags, $stream_id) =
            unpack("CCC C C N", substr($data, 0, 9, ''));

        my $length = ($len_hi << 16) | ($len_mid << 8) | $len_lo;
        $stream_id &= 0x7FFFFFFF;

        last if length($data) < $length;

        my $payload = substr($data, 0, $length, '');

        my $frame = {
            type      => $type,
            flags     => $flags,
            stream_id => $stream_id,
            length    => $length,
            payload   => $payload,
        };

        # Parse SETTINGS frame payload
        if ($type == FRAME_SETTINGS && $length > 0 && !($flags & FLAG_ACK)) {
            $frame->{settings} = parse_settings_payload($payload);
        }

        push @frames, $frame;
    }

    return @frames;
}
