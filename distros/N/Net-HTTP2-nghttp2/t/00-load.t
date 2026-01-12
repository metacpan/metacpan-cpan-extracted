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

done_testing;
