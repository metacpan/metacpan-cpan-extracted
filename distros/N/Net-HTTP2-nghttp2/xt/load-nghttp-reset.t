use strict;
use warnings;
use Test::More;
use FindBin ();
use IO::Socket::INET;
use Time::HiRes ();
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../t/lib";

# Streams cancelled mid-body, 500 of them on one connection, against a server
# running under MallocScribble. h2load opens a connection per client and tears
# it down at the end of the run, which is exactly where a per-connection leak
# hides; this drives one long-lived connection instead, the shape a real server
# lives in.
#
# The rounds are driven by a raw client built from the frame helpers in t/lib,
# which the brief allows in place of nghttp: nghttp cancels by closing the
# connection, so it cannot keep 500 resets on one session. nghttp still runs
# here, against the same endpoint, to keep a real client in the picture.

use Test::HTTP2::Frame qw(
    CLIENT_PREFACE
    build_settings_frame
    build_headers_frame
    build_rst_stream_frame
    build_window_update_frame
    parse_frames
    FRAME_DATA
    FRAME_HEADERS
    FRAME_SETTINGS
    FRAME_GOAWAY
    FLAG_ACK
    ERROR_CANCEL
);
use Test::HTTP2::HPACK qw(encode_headers);
use Test::HTTP2::LoadServer qw(
    start_server stop_server server_alive child_pids child_rss wait_for_stats sum_stats
);

use constant ROUNDS        => 500;
use constant CHUNKS        => 100;    # /stream?n=100, 100 KiB per response
use constant WINDOW_REFILL => 16384;
use constant READ_TIMEOUT  => 5;

# One provider per reset would be a few hundred bytes; 500 of them is under a
# megabyte, so this bound is coarse. It catches a leak that scales with the
# body rather than with the stream count, and t/36 does the exact accounting.
use constant CHILD_RSS_GROWTH_LIMIT_KB => 2048;

# A write to a connection the server gave up on must fail the assertions that
# follow, not kill the test with a signal.
$SIG{PIPE} = 'IGNORE';

my $server;
END { stop_server($server) if $server }

$server = start_server(
    stats => 1,
    env   => { MallocScribble => 1, MallocPreScribble => 1 },
);
ok(server_alive($server), "h2spec-server is listening on port $server->{port}");
note("server pid $server->{pid}, log $server->{log}, MallocScribble=1");

my @probe = wait_for_stats($server, 1);
my $stats_seen = scalar @probe;

subtest 'nghttp fetches the streaming endpoint' => sub {
    my $nghttp = find_tool('nghttp');
    plan skip_all => 'nghttp is not installed' unless $nghttp;

    my $url = "http://127.0.0.1:$server->{port}/stream?n=10";
    my $body = `$nghttp -n --stat '$url' 2>&1`;
    is($?, 0, 'nghttp exited 0');
    like($body, qr{\s 200 \s+ \S+ \s+ /stream\?n=10}x,
        'nghttp reported a 200 for the streaming endpoint')
        or diag($body);

    my $bytes = `$nghttp '$url' 2>/dev/null | wc -c`;
    $bytes =~ s/\s+//g;
    is($bytes, 10 * 1024, 'nghttp received the whole streaming body');

    $stats_seen = scalar wait_for_stats($server, $stats_seen + 2);
};

subtest ROUNDS . ' streams cancelled mid-body on one connection' => sub {
    my $socket = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => $server->{port},
        Proto    => 'tcp',
        Timeout  => 5,
    ) or die "cannot connect to the server: $!";
    $socket->autoflush(1);

    print {$socket} CLIENT_PREFACE . build_settings_frame(settings => {});

    my %client = (
        socket       => $socket,
        buffer       => '',
        unacked      => 0,
        data_bytes   => 0,
        data_streams => {},
        goaway       => 0,
    );

    my @rss_samples;
    my $first_child;
    my $reset_rounds = 0;
    my $body_seen    = 0;

    for my $round (1 .. ROUNDS) {
        my $stream_id = $round * 2 - 1;

        print {$socket} build_headers_frame(
            stream_id    => $stream_id,
            end_stream   => 1,
            end_headers  => 1,
            header_block => encode_headers([
                [':method',    'GET'],
                [':scheme',    'http'],
                [':authority', "127.0.0.1:$server->{port}"],
                [':path',      '/stream?n=' . CHUNKS],
            ]),
        );

        # Read until the body has started, then cancel it.
        my $started = pump(\%client, sub { $client{data_streams}{$stream_id} });
        $body_seen++ if $started;

        print {$socket} build_rst_stream_frame(
            stream_id  => $stream_id,
            error_code => ERROR_CANCEL,
        );
        $reset_rounds++;

        if ($client{unacked} >= WINDOW_REFILL) {
            print {$socket} build_window_update_frame(
                stream_id => 0,
                increment => $client{unacked},
            );
            $client{unacked} = 0;
        }

        last if $client{goaway};

        if ($round % 50 == 0 || $round == 1) {
            my ($child) = child_pids($server);
            $first_child //= $child;
            my $rss = defined $child ? child_rss($child) : undef;
            push @rss_samples, [$round, $rss] if defined $rss;
        }
    }

    is($reset_rounds, ROUNDS, 'every round cancelled its stream');
    is($body_seen, ROUNDS, 'every cancelled stream had started its body');
    ok(!$client{goaway}, 'the server never gave up on the connection');
    ok(server_alive($server), 'the listening process survived the run');

    note(sprintf 'connection child RSS: %s',
        join ', ', map { "round $_->[0]: $_->[1] KiB" } @rss_samples);
    if (@rss_samples >= 2) {
        my $growth = $rss_samples[-1][1] - $rss_samples[0][1];
        note("connection child RSS growth across the run: $growth KiB");
        cmp_ok($growth, '<=', CHILD_RSS_GROWTH_LIMIT_KB,
            'the connection process did not grow with the cancelled streams');
    }

    # The connection still works after 500 cancellations.
    my $final_stream = ROUNDS * 2 + 1;
    print {$socket} build_headers_frame(
        stream_id    => $final_stream,
        end_stream   => 1,
        end_headers  => 1,
        header_block => encode_headers([
            [':method',    'GET'],
            [':scheme',    'http'],
            [':authority', "127.0.0.1:$server->{port}"],
            [':path',      '/echo'],
        ]),
    );
    print {$socket} build_window_update_frame(stream_id => 0, increment => 1 << 20);
    ok(pump(\%client, sub { $client{data_streams}{$final_stream} }),
        'the connection still answers a request after the cancellations');

    note("total response body bytes received: $client{data_bytes}");
    close $socket;

    my @stats = wait_for_stats($server, $stats_seen + 1);
    my @fresh = @stats[$stats_seen .. $#stats];
    $stats_seen = scalar @stats;
    my $totals = sum_stats(@fresh);

    is($totals->{connections}, 1, 'the run used one connection');
    is($totals->{streams}, ROUNDS + 1, 'the server accepted every request');
    is($totals->{invalid_frames}, 0, 'no invalid frame arrived');
    is($totals->{errors}, 0, 'nghttp2 reported no error');

    my $data_frames = $totals->{sent}{ FRAME_DATA() } || 0;
    note(sprintf 'server counters: streams=%d data_frames=%d not_sent={%s}',
        $totals->{streams}, $data_frames,
        join ',', map { "$_=$totals->{not_sent}{$_}" } sort keys %{ $totals->{not_sent} });

    cmp_ok($data_frames, '>', 0, 'the server was sending bodies when the resets landed');
    cmp_ok($data_frames, '<', ROUNDS * CHUNKS,
        'the resets cut the bodies short, which is what they were for');

    # Anything nghttp2 discarded here was discarded because the stream was
    # closing under it. -511 is NGHTTP2_ERR_STREAM_CLOSING, -510 is
    # NGHTTP2_ERR_STREAM_CLOSED.
    my @unexpected = grep { $_ != -510 && $_ != -511 } keys %{ $totals->{not_sent} };
    is_deeply(\@unexpected, [],
        'every discarded frame was discarded by a reset');
};

done_testing;

sub find_tool {
    my ($name) = @_;
    for my $dir (split /:/, $ENV{PATH} || '') {
        next unless length $dir;
        my $path = "$dir/$name";
        return $path if -x $path && !-d $path;
    }
    return undef;
}

# Read and account for frames until $ready is true or the read times out.
sub pump {
    my ($client, $ready) = @_;
    my $deadline = Time::HiRes::time() + READ_TIMEOUT;

    while (Time::HiRes::time() < $deadline) {
        return 1 if $ready->();

        my $rin = '';
        vec($rin, fileno($client->{socket}), 1) = 1;
        my $found = select($rin, undef, undef, 0.2);
        next unless $found && $found > 0;

        my $chunk;
        my $read = sysread($client->{socket}, $chunk, 65536);
        return 0 if !defined $read || $read == 0;
        $client->{buffer} .= $chunk;

        my ($frames, $rest) = parse_frames($client->{buffer});
        $client->{buffer} = $rest;
        for my $frame (@$frames) {
            if ($frame->{type} == FRAME_DATA) {
                $client->{data_bytes} += $frame->{length};
                $client->{unacked}    += $frame->{length};
                $client->{data_streams}{ $frame->{stream_id} } += $frame->{length}
                    if $frame->{length};
            }
            elsif ($frame->{type} == FRAME_SETTINGS && !($frame->{flags} & FLAG_ACK)) {
                print { $client->{socket} } build_settings_frame(ack => 1);
            }
            elsif ($frame->{type} == FRAME_GOAWAY) {
                $client->{goaway} = 1;
            }
        }
    }
    return $ready->() ? 1 : 0;
}
