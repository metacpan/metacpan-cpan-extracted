use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Net::HTTP2::nghttp2 qw(NGHTTP2_CANCEL);
use Net::HTTP2::nghttp2::Session;
use Test::HTTP2::Frame qw(FRAME_HEADERS);
use Test::HTTP2::Pair qw(new_session_pair pump_sessions);

# The Rapid Reset shape at volume: the peer opens a stream and resets it, and
# the server answers the request it already accepted. Every one of those
# responses is discarded by nghttp2, and every one registers a data provider
# holding a Perl callback_data. If those are only reclaimed when the session
# goes away, a long-lived connection grows without bound. Nothing new is
# exposed to count them: each callback_data counts its own destruction, so
# submissions minus destructions is the number of providers still live.

use constant RESET_ROUNDS  => 2000;
use constant NORMAL_EVERY  => 10;     # 200 normal streams among the resets
use constant NORMAL_BODY   => 'normal-body';

# The provider count must stay flat, not merely bounded: at most the response
# being submitted this round and the normal response sharing the round with it.
use constant MAX_LIVE_PROVIDERS => 2;

my $submitted = 0;
my $destroyed = 0;

{
    package Test::Provider::Counter;

    sub new {
        my ($class) = @_;
        $submitted++;
        return bless {}, $class;
    }

    sub DESTROY {
        $destroyed++;
        return;
    }
}

sub request_args {
    my ($path) = @_;
    return (
        method    => 'GET',
        scheme    => 'https',
        authority => 'example.test',
        path      => $path,
    );
}

my (@streams, @not_sent_errors, %bodies, @closed);

my ($client, $server) = new_session_pair(
    # This test is about provider lifetime under a reset flood, not about the
    # rate limiter t/22 covers; raise it so nghttp2 does not end the session
    # partway through.
    server_args => {
        stream_reset_burst => 100_000,
        stream_reset_rate  => 100_000,
    },
    server_callbacks => {
        on_frame_recv => sub {
            my ($frame) = @_;
            push @streams, $frame->{stream_id}
                if $frame->{type} == FRAME_HEADERS && $frame->{stream_id} > 0;
            return 0;
        },
        on_frame_not_send => sub {
            my ($frame, $lib_error_code) = @_;
            push @not_sent_errors, $lib_error_code;
            return 0;
        },
        on_stream_close => sub {
            push @closed, $_[0];
            return 0;
        },
    },
    client_callbacks => {
        on_data_chunk_recv => sub {
            my ($stream_id, $data) = @_;
            $bodies{$stream_id} .= $data;
            return 0;
        },
    },
);

my $max_live = 0;
my $normal_streams = 0;
my $normal_complete = 0;

# Sampled both while a response is in flight and once every round has drained,
# so the peak reflects providers actually held, not just leftovers.
sub sample_live {
    my $live = $submitted - $destroyed;
    $max_live = $live if $live > $max_live;
    return;
}

for my $round (1 .. RESET_ROUNDS) {
    # Open a stream, reset it, then answer the request the server accepted.
    my $client_stream = $client->submit_request(request_args("/reset/$round"));
    pump_sessions($client, $server);
    $client->submit_rst_stream($client_stream, NGHTTP2_CANCEL);
    pump_sessions($client, $server);

    my $produced = 0;
    $server->submit_response(
        $streams[-1],
        status        => 200,
        body          => sub { return (undef) if $produced++; return ('late-body', 1) },
        callback_data => Test::Provider::Counter->new,
    );
    sample_live();
    pump_sessions($client, $server);

    if ($round % NORMAL_EVERY == 0) {
        $normal_streams++;
        my $normal_client_stream = $client->submit_request(request_args("/normal/$round"));
        pump_sessions($client, $server);

        my $sent = 0;
        $server->submit_response(
            $streams[-1],
            status        => 200,
            body          => sub { return ('', 1) if $sent++; return (NORMAL_BODY, 1) },
            callback_data => Test::Provider::Counter->new,
        );
        sample_live();
        pump_sessions($client, $server);

        $normal_complete++
            if defined $bodies{$normal_client_stream}
            && $bodies{$normal_client_stream} eq NORMAL_BODY;
    }

    sample_live();
}

is($submitted, RESET_ROUNDS + $normal_streams,
    'every round submitted a response carrying a callback_data');
is($normal_streams, RESET_ROUNDS / NORMAL_EVERY, 'the normal streams were interleaved');
is($normal_complete, $normal_streams,
    'every normal stream received its response body in full');
is(scalar(grep { $_ != -510 } @not_sent_errors), 0,
    'every discarded frame was reported as NGHTTP2_ERR_STREAM_CLOSED (-510)');
is(scalar @not_sent_errors, RESET_ROUNDS,
    'one discarded response per reset stream');

cmp_ok($max_live, '<=', MAX_LIVE_PROVIDERS,
    "no more than " . MAX_LIVE_PROVIDERS . " providers were ever live at once (peak $max_live)");
is($submitted - $destroyed, 0,
    'every callback_data was destroyed while the session was still alive');

# The session survived the flood and still answers.
my $final_client_stream = $client->submit_request(request_args('/final'));
pump_sessions($client, $server);
my $final_sent = 0;
$server->submit_response(
    $streams[-1],
    status        => 200,
    body          => sub { return ('', 1) if $final_sent++; return ('final-body', 1) },
    callback_data => Test::Provider::Counter->new,
);
pump_sessions($client, $server);
is($bodies{$final_client_stream}, 'final-body',
    'the session still answers a request after the flood');

undef $server;
undef $client;
is($submitted - $destroyed, 0, 'nothing was left for session destruction to release');

done_testing;
