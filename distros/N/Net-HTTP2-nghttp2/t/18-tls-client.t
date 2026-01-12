#!/usr/bin/env perl
# TLS client integration test - connects to real HTTPS server
# Only runs when DEVTESTING=1 to avoid network dependencies during install

use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => 'Set DEVTESTING=1 to run TLS integration tests'
        unless $ENV{DEVTESTING};
}

use Net::HTTP2::nghttp2;
use Net::HTTP2::nghttp2::Session;

plan skip_all => 'nghttp2 not available' unless Net::HTTP2::nghttp2->available;

# Check for IO::Socket::SSL
eval { require IO::Socket::SSL; IO::Socket::SSL->VERSION(1.56); };
plan skip_all => 'IO::Socket::SSL 1.56+ required for TLS tests' if $@;

plan tests => 9;

# Test connecting to nghttp2.org which supports HTTP/2
my $host = 'nghttp2.org';
my $port = 443;

# Create TLS connection with ALPN
my $sock = IO::Socket::SSL->new(
    PeerHost        => $host,
    PeerPort        => $port,
    SSL_alpn_protocols => ['h2'],
    SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_PEER(),
) or do {
    diag "SSL connection failed: $!";
    BAIL_OUT("Cannot connect to $host:$port");
};

# Verify ALPN negotiated h2
my $alpn = $sock->alpn_selected();
is($alpn, 'h2', 'ALPN negotiated HTTP/2');

# Track response data
my %responses;
my $headers_done = 0;

# Create client session
my $session = Net::HTTP2::nghttp2::Session->new_client(
    callbacks => {
        on_begin_headers => sub {
            my ($stream_id) = @_;
            $responses{$stream_id} = { headers => {}, data => '' };
            return 0;
        },
        on_header => sub {
            my ($stream_id, $name, $value) = @_;
            $responses{$stream_id}{headers}{$name} = $value;
            return 0;
        },
        on_frame_recv => sub {
            my ($frame) = @_;
            if ($frame->{type} == 1 && ($frame->{flags} & 0x4)) {  # HEADERS with END_HEADERS
                $headers_done = 1;
            }
            return 0;
        },
        on_data_chunk_recv => sub {
            my ($stream_id, $data) = @_;
            $responses{$stream_id}{data} .= $data;
            return 0;
        },
        on_stream_close => sub {
            my ($stream_id, $error_code) = @_;
            $responses{$stream_id}{closed} = 1;
            $responses{$stream_id}{error_code} = $error_code;
            return 0;
        },
    },
);

ok($session, 'Created client session');

# Send client connection preface
$session->send_connection_preface();

# Submit a GET request
my $stream_id = $session->submit_request(
    method    => 'GET',
    path      => '/',
    scheme    => 'https',
    authority => $host,
    headers   => [
        ['user-agent', 'Net-HTTP2-nghttp2-test/0.001'],
        ['accept', '*/*'],
    ],
);

ok($stream_id > 0, "Submitted request on stream $stream_id");

# I/O loop
$sock->blocking(1);
my $timeout = 10;
my $start = time();

while (time() - $start < $timeout) {
    # Send pending data
    my $out = $session->mem_send();
    if (defined $out && length $out) {
        my $written = $sock->syswrite($out);
        last unless defined $written;
    }

    # Check if done
    last if $responses{$stream_id} && $responses{$stream_id}{closed};
    last unless $session->want_read() || $session->want_write();

    # Read with timeout using select
    my $rin = '';
    vec($rin, fileno($sock), 1) = 1;
    my $ready = select($rin, undef, undef, 1);

    if ($ready > 0) {
        my $buf;
        my $n = $sock->sysread($buf, 16384);
        last if !defined $n || $n == 0;

        $session->mem_recv($buf);

        # Flush any responses
        while (1) {
            my $out2 = $session->mem_send();
            last unless defined $out2 && length $out2;
            $sock->syswrite($out2);
        }
    }
}

$sock->close();

# Verify response
ok(exists $responses{$stream_id}, 'Got response for stream');

my $resp = $responses{$stream_id};
ok($resp->{headers}, 'Got response headers');

my $status = $resp->{headers}{':status'};
ok(defined $status, 'Got :status header');
like($status, qr/^[23]\d\d$/, "Status is success/redirect: $status");

ok(length($resp->{data}) > 0, 'Got response body: ' . length($resp->{data}) . ' bytes');

is($resp->{error_code}, 0, 'Stream closed without error');

diag "Response status: $status";
diag "Response body length: " . length($resp->{data}) . " bytes";
diag "Response headers: " . join(', ', map { "$_=$resp->{headers}{$_}" }
    grep { /^:/ } keys %{$resp->{headers}});
