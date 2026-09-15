use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Net::HTTP2::nghttp2 qw(NGHTTP2_ERR_PROTO NGHTTP2_ERR_HTTP_HEADER);
use Net::HTTP2::nghttp2::Session;
use Test::HTTP2::Frame qw(
    CLIENT_PREFACE FRAME_GOAWAY FRAME_WINDOW_UPDATE
    build_settings_frame build_headers_frame build_window_update_frame
    parse_frames
);
use Test::HTTP2::HPACK qw(encode_headers);

# Feed a server session raw bytes, so the peer frame is exactly as written
# rather than as a well-behaved client session would have produced it.
sub feed_server {
    my (%args) = @_;

    my $server = Net::HTTP2::nghttp2::Session->new_server(
        callbacks => {
            on_begin_headers => sub { return 0 },
            on_header        => sub { return 0 },
            on_frame_recv    => sub { return 0 },
            %{ $args{callbacks} || {} },
        },
    );

    $server->send_connection_preface;
    $server->mem_send;
    $server->mem_recv(CLIENT_PREFACE . build_settings_frame());
    $server->mem_send;
    $server->mem_recv($args{bytes});

    my ($frames) = parse_frames($server->mem_send);
    return ($server, $frames);
}

sub request_headers {
    my (@extra) = @_;
    return encode_headers([
        [':method',    'POST'],
        [':path',      '/'],
        [':scheme',    'https'],
        [':authority', 'localhost'],
        @extra,
    ]);
}

# A WINDOW_UPDATE whose increment is zero is a protocol error (RFC 9113 s6.9).
sub zero_window_update_bytes {
    return build_headers_frame(
        stream_id    => 1,
        header_block => request_headers(),
        end_stream   => 0,
        end_headers  => 1,
    ) . build_window_update_frame(stream_id => 1, increment => 0);
}

subtest 'a rejected frame reaches on_invalid_frame_recv' => sub {
    my @invalid;

    my ($server, $frames) = feed_server(
        bytes     => zero_window_update_bytes(),
        callbacks => {
            on_invalid_frame_recv => sub {
                my ($frame, $lib_error_code) = @_;
                push @invalid, { frame => {%$frame}, error => $lib_error_code };
                return 0;
            },
        },
    );

    is(scalar @invalid, 1, 'the rejected frame was reported once');
    is($invalid[0]{frame}{type}, FRAME_WINDOW_UPDATE,
        'the report carries the rejected frame');
    is($invalid[0]{frame}{stream_id}, 1, 'the report names the stream');
    is($invalid[0]{error}, NGHTTP2_ERR_PROTO,
        'the rejection is reported as NGHTTP2_ERR_PROTO');

    ok(
        scalar(grep { $_->{type} == FRAME_GOAWAY } @$frames),
        'nghttp2 tore the connection down itself',
    );
};

subtest 'nghttp2 diagnostics reach on_error' => sub {
    my @errors;

    # A connection-specific header field is not allowed in HTTP/2 (s8.2.2).
    my ($server, $frames) = feed_server(
        bytes => build_headers_frame(
            stream_id    => 1,
            header_block => request_headers(['connection', 'keep-alive']),
            end_stream   => 1,
            end_headers  => 1,
        ),
        callbacks => {
            on_error => sub {
                my ($lib_error_code, $message) = @_;
                push @errors, { error => $lib_error_code, message => $message };
                return 0;
            },
        },
    );

    is(scalar @errors, 1, 'nghttp2 reported the rejection through on_error');
    is($errors[0]{error}, NGHTTP2_ERR_HTTP_HEADER,
        'the bad header field is reported as NGHTTP2_ERR_HTTP_HEADER');
    ok(!ref $errors[0]{message}, 'the message is a plain string');
    # nghttp2 documents the wording as free to change between versions, so
    # only its presence is pinned here.
    ok(length $errors[0]{message}, 'the message is not empty');
};

subtest 'the callbacks are optional' => sub {
    my ($server, $frames) = feed_server(bytes => zero_window_update_bytes());

    ok(
        scalar(grep { $_->{type} == FRAME_GOAWAY } @$frames),
        'a session without either callback still rejects the frame',
    );
};

done_testing;
