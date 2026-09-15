use strict;
use warnings;
use Test::More;
use File::Temp ();
use FindBin ();
use lib "$FindBin::Bin/lib";

# The 0.010/0.011 callback surface under load, through the example server:
# on_frame_send resetting the request half of an early response, on_frame_recv
# driving streaming bodies, the frame counters, and the GOAWAY shutdown. Every
# h2load summary is captured whole and reported.

use Test::HTTP2::LoadServer qw(
    start_server stop_server server_alive server_rss wait_for_stats sum_stats
);

my $h2load = find_tool('h2load');
plan skip_all => 'h2load is not installed' unless $h2load;

# Frame types, for the --stats counters.
use constant {
    FRAME_DATA       => 0,
    FRAME_HEADERS    => 1,
    FRAME_RST_STREAM => 3,
    FRAME_GOAWAY     => 7,
};

# The parent process holds no session state (it forks per connection), so its
# resident size should not move at all across a run. A megabyte of slack
# covers allocator noise and still catches anything structural.
use constant RSS_GROWTH_LIMIT_KB => 1024;

my $server;
END { stop_server($server) if $server }

$server = start_server(stats => 1);
ok(server_alive($server), "h2spec-server is listening on port $server->{port}");
note("server pid $server->{pid}, log $server->{log}");

my $upload = File::Temp->new(
    TEMPLATE => 'h2load-body-XXXXXX', SUFFIX => '.bin', TMPDIR => 1);
print {$upload} ('u' x 1024) for 1 .. 1024;    # 1 MiB
close $upload;

# start_server probes the listener with one throwaway connection, which the
# server reports like any other. Consume that line before the load runs.
my @probe = wait_for_stats($server, 1);
my $stats_seen = scalar @probe;
is($stats_seen, 1, 'the readiness probe was reported and set aside');

subtest 'h2load -n 20000 -c 50 -m 100 against /echo' => sub {
    my $summary = run_h2load(
        [qw(-n 20000 -c 50 -m 100)],
        "http://127.0.0.1:$server->{port}/echo",
        50,
    );

    is($summary->{succeeded}, 20000, 'every request succeeded');
    is($summary->{failed},    0,     'no request failed');
    is($summary->{errored},   0,     'no request errored');
    is($summary->{'2xx'},     20000, 'every response was 2xx');

    my $totals = $summary->{stats};
    is($totals->{connections}, 50, 'the server saw 50 connections');
    is($totals->{streams}, 20000, 'the server accepted 20000 streams');
    is($totals->{sent}{ FRAME_HEADERS() }, 20000, 'one response HEADERS per stream');
    is($totals->{early_resets}, 0,
        'a request that ends before the response needs no reset');
    is_deeply($totals->{not_sent}, {}, 'no frame was discarded');
    is($totals->{invalid_frames}, 0, 'no invalid frame arrived');
    is($totals->{errors}, 0, 'nghttp2 reported no error');
};

subtest 'h2load -n 5000 -c 20 -m 50 -d 1MiB against /early' => sub {
    my $summary = run_h2load(
        [qw(-n 5000 -c 20 -m 50 -d), "$upload"],
        "http://127.0.0.1:$server->{port}/early",
        20,
    );

    is($summary->{succeeded}, 5000, 'every request succeeded');
    is($summary->{failed},    0,    'no request failed');
    is($summary->{errored},   0,    'no request errored');
    is($summary->{'2xx'},     5000, 'every response was 2xx');

    my $totals = $summary->{stats};
    is($totals->{connections}, 20, 'the server saw 20 connections');
    is($totals->{streams}, 5000, 'the server accepted 5000 streams');
    is($totals->{early_resets}, 5000,
        'every early response reset its still-open request half');
    is($totals->{sent}{ FRAME_RST_STREAM() }, 5000,
        'every one of those resets reached the wire');

    # The response is fully serialized before the RST_STREAM is queued, so the
    # reset discards nothing of ours: not_sent stays empty.
    is_deeply($totals->{not_sent}, {},
        'the early resets discarded no frame of our own');
    is($totals->{invalid_frames}, 0, 'no invalid frame arrived');
    is($totals->{errors}, 0, 'nghttp2 reported no error');
};

subtest 'h2load -n 5000 -c 20 -m 50 against /stream?n=50' => sub {
    my $summary = run_h2load(
        [qw(-n 5000 -c 20 -m 50)],
        "http://127.0.0.1:$server->{port}/stream?n=50",
        20,
    );

    is($summary->{succeeded}, 5000, 'every request succeeded');
    is($summary->{failed},    0,    'no request failed');
    is($summary->{errored},   0,    'no request errored');
    is($summary->{'2xx'},     5000, 'every response was 2xx');
    is($summary->{data_bytes}, 5000 * 50 * 1024,
        'every streaming body arrived whole');

    my $totals = $summary->{stats};
    is($totals->{streams}, 5000, 'the server accepted 5000 streams');
    cmp_ok($totals->{sent}{ FRAME_DATA() }, '>=', 5000 * 50,
        'the streaming bodies were sent a chunk at a time');
    is($totals->{early_resets}, 0, 'a completed request needs no reset');
    is_deeply($totals->{not_sent}, {}, 'no frame was discarded');
    is($totals->{errors}, 0, 'nghttp2 reported no error');
};

subtest 'SIGTERM mid-run announces GOAWAY and exits 0' => sub {
    my $before = server_rss($server);

    my $output = File::Temp->new(
        TEMPLATE => 'h2load-term-XXXXXX', SUFFIX => '.txt', TMPDIR => 1);
    my $pid = fork();
    die "fork failed: $!" unless defined $pid;
    unless ($pid) {
        open STDOUT, '>&', $output or die $!;
        open STDERR, '>&', $output or die $!;
        exec $h2load, qw(-n 40000 -c 20 -m 50),
            "http://127.0.0.1:$server->{port}/stream?n=50"
            or die $!;
    }

    # Long enough for h2load to be well into the run.
    select undef, undef, undef, 0.5;
    ok(server_alive($server), 'the server was still running when SIGTERM was sent');
    my $status = stop_server($server);
    waitpid($pid, 0);

    is($status, 0, 'the server exited 0 after SIGTERM');

    my $summary = parse_h2load(slurp("$output"));
    note_summary('SIGTERM mid-run', $summary);
    cmp_ok($summary->{started}, '<', 40000,
        'h2load stopped starting requests when the connections went away');
    cmp_ok($summary->{failed}, '>', 0,
        'h2load reported the requests the server would not take');

    my $totals = fresh_stats(20);
    note("server counters: " . counters_note($totals));
    is($totals->{connections}, 20, 'every connection reported its counters');
    is($totals->{sent}{ FRAME_GOAWAY() }, 20,
        'every connection announced GOAWAY before exiting');
    note("RSS before SIGTERM: ${before} KiB");
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

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or return '';
    local $/;
    my $content = <$fh>;
    close $fh;
    return defined $content ? $content : '';
}

sub parse_h2load {
    my ($output) = @_;
    my %summary = (raw => $output);

    if ($output =~ /^requests: \s* (\d+) \s* total, \s* (\d+) \s* started, \s*
                     (\d+) \s* done, \s* (\d+) \s* succeeded, \s* (\d+) \s* failed, \s*
                     (\d+) \s* errored, \s* (\d+) \s* timeout/xm) {
        @summary{qw(total started done succeeded failed errored timeout)} =
            ($1, $2, $3, $4, $5, $6, $7);
    }
    if ($output =~ /^status \s+ codes: \s* (\d+) \s* 2xx, \s* (\d+) \s* 3xx, \s*
                     (\d+) \s* 4xx, \s* (\d+) \s* 5xx/xm) {
        @summary{qw(2xx 3xx 4xx 5xx)} = ($1, $2, $3, $4);
    }
    if ($output =~ /^traffic: .* \( (\d+) \) \s* total, .* \( (\d+) \) \s* headers .*?
                     \( (\d+) \) \s* data/xm) {
        @summary{qw(total_bytes header_bytes data_bytes)} = ($1, $2, $3);
    }
    ($summary{finished}) = $output =~ /^(finished in .*)$/m;
    return \%summary;
}

sub note_summary {
    my ($label, $summary) = @_;
    note("$label: " . ($summary->{finished} // 'no timing line'));
    note("$label: requests $summary->{total} total, $summary->{started} started, "
            . "$summary->{done} done, $summary->{succeeded} succeeded, "
            . "$summary->{failed} failed, $summary->{errored} errored")
        if defined $summary->{total};
    note("$label: data bytes " . ($summary->{data_bytes} // 'unknown'));
    return;
}

# Run one h2load, check the server survived it, and collect the per-connection
# counters for exactly that run.
sub run_h2load {
    my ($options, $url, $connections) = @_;

    my $rss_before = server_rss($server);
    my $output = File::Temp->new(
        TEMPLATE => 'h2load-XXXXXX', SUFFIX => '.txt', TMPDIR => 1);
    close $output;

    my $command = join ' ', map { quote($_) } $h2load, @$options, $url;
    system("$command > " . quote("$output") . " 2>&1");
    my $exit = $?;

    my $summary = parse_h2load(slurp("$output"));
    note_summary($url, $summary);
    is($exit, 0, "h2load exited 0 ($url)");
    ok(server_alive($server), "the server is still running after $url");

    my $rss_after = server_rss($server);
    note("RSS: before ${rss_before} KiB, after ${rss_after} KiB, growth "
            . ($rss_after - $rss_before) . ' KiB');
    cmp_ok($rss_after - $rss_before, '<=', RSS_GROWTH_LIMIT_KB,
        'the listening process did not grow across the run');

    $summary->{stats} = fresh_stats($connections);
    note("server counters: " . counters_note($summary->{stats}));

    return $summary;
}

# The counters for the connections that closed since the last call.
sub fresh_stats {
    my ($connections) = @_;
    my @stats = wait_for_stats($server, $stats_seen + $connections);
    my @fresh = @stats[$stats_seen .. $#stats];
    $stats_seen = scalar @stats;
    return sum_stats(@fresh);
}

sub counters_note {
    my ($totals) = @_;
    return sprintf(
        'connections=%d streams=%d early_resets=%d invalid=%d errors=%d sent={%s} not_sent={%s}',
        $totals->{connections}, $totals->{streams}, $totals->{early_resets},
        $totals->{invalid_frames}, $totals->{errors},
        join(',', map { "$_=$totals->{sent}{$_}" } sort { $a <=> $b } keys %{ $totals->{sent} }),
        join(',', map { "$_=$totals->{not_sent}{$_}" } sort { $a <=> $b } keys %{ $totals->{not_sent} }),
    );
}

sub quote {
    my ($word) = @_;
    $word =~ s/'/'\\''/g;
    return "'$word'";
}
