# Backpressure Test App
#
# Test app for benchmarking send-side backpressure behavior.
# Streams large amounts of data as fast as possible to stress-test
# the write buffer and backpressure mechanism.
#
# USAGE:
#   # Enable the stress test endpoint
#   PAGI_BACKPRESSURE_TEST=1 pagi-server --app examples/backpressure-test/app.pl
#
#   # Or with custom watermarks (to compare behavior)
#   PAGI_BACKPRESSURE_TEST=1 pagi-server --app examples/backpressure-test/app.pl \
#       --write-high-watermark 1048576 --write-low-watermark 262144
#
# ENDPOINTS:
#   GET /           - Health check, returns server info
#   GET /stream     - Streams ~10MB of data in 4KB chunks (requires PAGI_BACKPRESSURE_TEST=1)
#   GET /stream/N   - Streams N megabytes (e.g., /stream/50 for 50MB)
#
# See README.md in this directory for benchmarking instructions.

use strict;
use warnings;
use Future::AsyncAwait;

# Configuration via environment
my $ENABLE_TEST    = $ENV{PAGI_BACKPRESSURE_TEST} // 0;
my $CHUNK_SIZE     = $ENV{PAGI_CHUNK_SIZE} // 4096;        # 4KB default
my $DEFAULT_MB     = $ENV{PAGI_STREAM_MB} // 10;           # 10MB default

# Pre-generate chunk data (random-ish bytes to prevent compression)
my $CHUNK_DATA = _generate_chunk($CHUNK_SIZE);

sub _generate_chunk {
    my ($size) = @_;
    # Use a repeating pattern that won't compress well
    my $pattern = join('', map { chr(32 + ($_ % 95)) } 0..255);
    my $chunk = '';
    while (length($chunk) < $size) {
        $chunk .= $pattern;
    }
    return substr($chunk, 0, $size);
}

# Drain request body
async sub drain_request {
    my ($receive) = @_;
    while (1) {
        my $event = await $receive->();
        last if $event->{type} ne 'http.request';
        last unless $event->{more};
    }
}

# Health check / info endpoint
async sub handle_info {
    my ($scope, $receive, $send) = @_;

    await drain_request($receive);

    my $info = <<"INFO";
PAGI Backpressure Test Server
==============================
Test endpoint enabled: @{[ $ENABLE_TEST ? 'YES' : 'NO' ]}
Chunk size: $CHUNK_SIZE bytes
Default stream size: ${DEFAULT_MB}MB

Endpoints:
  GET /         - This info page
  GET /stream   - Stream ${DEFAULT_MB}MB of data (requires PAGI_BACKPRESSURE_TEST=1)
  GET /stream/N - Stream N megabytes

Environment variables:
  PAGI_BACKPRESSURE_TEST=1  - Enable stress test endpoints
  PAGI_CHUNK_SIZE=N         - Chunk size in bytes (default: 4096)
  PAGI_STREAM_MB=N          - Default megabytes to stream (default: 10)
INFO

    await $send->({
        type    => 'http.response.start',
        status  => 200,
        headers => [
            ['content-type', 'text/plain; charset=utf-8'],
            ['content-length', length($info)],
        ],
    });
    await $send->({
        type => 'http.response.body',
        body => $info,
        more => 0,
    });
}

# Streaming stress test endpoint
async sub handle_stream {
    my ($scope, $receive, $send, $megabytes) = @_;

    await drain_request($receive);

    unless ($ENABLE_TEST) {
        my $msg = "Stress test disabled. Set PAGI_BACKPRESSURE_TEST=1 to enable.\n";
        await $send->({
            type    => 'http.response.start',
            status  => 403,
            headers => [
                ['content-type', 'text/plain'],
                ['content-length', length($msg)],
            ],
        });
        await $send->({
            type => 'http.response.body',
            body => $msg,
            more => 0,
        });
        return;
    }

    my $total_bytes = $megabytes * 1024 * 1024;
    my $chunks_needed = int($total_bytes / $CHUNK_SIZE);
    my $remainder = $total_bytes % $CHUNK_SIZE;

    # Start response with chunked encoding
    await $send->({
        type    => 'http.response.start',
        status  => 200,
        headers => [
            ['content-type', 'application/octet-stream'],
            ['x-stream-size', $total_bytes],
            ['x-chunk-size', $CHUNK_SIZE],
            ['x-chunk-count', $chunks_needed + ($remainder ? 1 : 0)],
        ],
    });

    # Stream chunks as fast as possible (no sleeps!)
    # Backpressure should naturally throttle this
    for my $i (1 .. $chunks_needed) {
        my $more = ($i < $chunks_needed || $remainder) ? 1 : 0;
        await $send->({
            type => 'http.response.body',
            body => $CHUNK_DATA,
            more => $more,
        });
    }

    # Send remainder if any
    if ($remainder) {
        await $send->({
            type => 'http.response.body',
            body => substr($CHUNK_DATA, 0, $remainder),
            more => 0,
        });
    }
}

# Main app router
async sub app {
    my ($scope, $receive, $send) = @_;

    # Only handle HTTP
    if ($scope->{type} ne 'http') {
        die "Unsupported scope type: $scope->{type}";
    }

    my $path = $scope->{path};

    if ($path eq '/') {
        await handle_info($scope, $receive, $send);
    }
    elsif ($path eq '/stream') {
        await handle_stream($scope, $receive, $send, $DEFAULT_MB);
    }
    elsif ($path =~ m{^/stream/(\d+)$}) {
        my $mb = $1;
        $mb = 1 if $mb < 1;
        $mb = 1000 if $mb > 1000;  # Cap at 1GB
        await handle_stream($scope, $receive, $send, $mb);
    }
    else {
        await drain_request($receive);
        my $msg = "Not found: $path\n";
        await $send->({
            type    => 'http.response.start',
            status  => 404,
            headers => [['content-type', 'text/plain'], ['content-length', length($msg)]],
        });
        await $send->({
            type => 'http.response.body',
            body => $msg,
            more => 0,
        });
    }
}

\&app;
