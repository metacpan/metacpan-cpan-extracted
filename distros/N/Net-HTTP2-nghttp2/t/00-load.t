use strict;
use warnings;
use Test::More;

use_ok('Net::HTTP2::nghttp2');

diag("Net::HTTP2::nghttp2 version: $Net::HTTP2::nghttp2::VERSION");

SKIP: {
    skip "nghttp2 not available", 3 unless Net::HTTP2::nghttp2->available;

    diag("nghttp2 library version: " . Net::HTTP2::nghttp2::version_string());
    diag("nghttp2 library version num: " . Net::HTTP2::nghttp2::version_num());

    ok(Net::HTTP2::nghttp2::version_string(), "version_string returns value");
    ok(Net::HTTP2::nghttp2::version_num() > 0, "version_num is positive");

    # Test constants
    ok(defined Net::HTTP2::nghttp2::NGHTTP2_FLAG_END_STREAM(), "NGHTTP2_FLAG_END_STREAM defined");
}

my @http2_error_names = qw(
    NGHTTP2_NO_ERROR
    NGHTTP2_PROTOCOL_ERROR
    NGHTTP2_INTERNAL_ERROR
    NGHTTP2_FLOW_CONTROL_ERROR
    NGHTTP2_SETTINGS_TIMEOUT
    NGHTTP2_STREAM_CLOSED
    NGHTTP2_FRAME_SIZE_ERROR
    NGHTTP2_REFUSED_STREAM
    NGHTTP2_CANCEL
    NGHTTP2_COMPRESSION_ERROR
    NGHTTP2_CONNECT_ERROR
    NGHTTP2_ENHANCE_YOUR_CALM
    NGHTTP2_INADEQUATE_SECURITY
    NGHTTP2_HTTP_1_1_REQUIRED
);

my @header_category_names = qw(
    NGHTTP2_HCAT_REQUEST
    NGHTTP2_HCAT_RESPONSE
    NGHTTP2_HCAT_PUSH_RESPONSE
    NGHTTP2_HCAT_HEADERS
);

my @library_error_names = qw(
    NGHTTP2_ERR_WOULDBLOCK
    NGHTTP2_ERR_CALLBACK_FAILURE
    NGHTTP2_ERR_TEMPORAL_CALLBACK_FAILURE
    NGHTTP2_ERR_DEFERRED
    NGHTTP2_ERR_STREAM_CLOSING
    NGHTTP2_ERR_PROTO
    NGHTTP2_ERR_HTTP_HEADER
);

is_deeply(
    [sort @{ $Net::HTTP2::nghttp2::EXPORT_TAGS{errors} }],
    [sort @library_error_names],
    ':errors contains the callback/library return errors',
);

is_deeply(
    [sort @{ $Net::HTTP2::nghttp2::EXPORT_TAGS{http2_errors} }],
    [sort @http2_error_names],
    ':http2_errors contains every HTTP/2 wire error code',
);

is_deeply(
    [sort @{ $Net::HTTP2::nghttp2::EXPORT_TAGS{header_categories} }],
    [sort @header_category_names],
    ':header_categories contains every nghttp2 header category',
);

for my $name (@Net::HTTP2::nghttp2::EXPORT_OK) {
    ok(Net::HTTP2::nghttp2->can($name), "$name is callable");
}

is(Net::HTTP2::nghttp2::NGHTTP2_INTERNAL_ERROR(), 2, 'INTERNAL_ERROR has its RFC value');
is(Net::HTTP2::nghttp2::NGHTTP2_CANCEL(), 8, 'CANCEL has its RFC value');
is(Net::HTTP2::nghttp2::NGHTTP2_ERR_STREAM_CLOSING(), -511, 'STREAM_CLOSING has its nghttp2 value');
is(Net::HTTP2::nghttp2::NGHTTP2_ERR_PROTO(), -505, 'PROTO has its nghttp2 value');
is(Net::HTTP2::nghttp2::NGHTTP2_ERR_HTTP_HEADER(), -531, 'HTTP_HEADER has its nghttp2 value');

done_testing;
