#!/usr/bin/env perl
# Rapid Reset (CVE-2023-44487) defense: the binding accepts and validates the
# stream-reset rate-limit options and passes them through to nghttp2. (nghttp2's
# own rate-limiter behaviour is exercised end-to-end at the PAGI-Server layer,
# against a real server session.)
use strict;
use warnings;
use Test::More;

use Net::HTTP2::nghttp2;
use Net::HTTP2::nghttp2::Session;

SKIP: {
    skip "nghttp2 not available", 1 unless Net::HTTP2::nghttp2->available;

    my %cb = (
        on_begin_headers => sub { return 0 },
        on_header        => sub { return 0 },
        on_frame_recv    => sub { return 0 },
    );

    # Both options together: session is created (option reaches nghttp2's
    # nghttp2_option_set_stream_reset_rate_limit without error).
    my $server = Net::HTTP2::nghttp2::Session->new_server(
        callbacks          => { %cb },
        stream_reset_burst => 3,
        stream_reset_rate  => 1,
    );
    isa_ok($server, 'Net::HTTP2::nghttp2::Session',
        'new_server accepts stream_reset_burst + stream_reset_rate');

    # The two options must be set together — partial config croaks.
    eval {
        Net::HTTP2::nghttp2::Session->new_server(
            callbacks => { %cb }, stream_reset_burst => 3,
        );
    };
    like($@, qr/must be set together/, 'stream_reset_burst alone croaks');

    eval {
        Net::HTTP2::nghttp2::Session->new_server(
            callbacks => { %cb }, stream_reset_rate => 1,
        );
    };
    like($@, qr/must be set together/, 'stream_reset_rate alone croaks');

    done_testing;
}
