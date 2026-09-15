use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Net::HTTP2::nghttp2 qw(NGHTTP2_NO_ERROR NGHTTP2_ENHANCE_YOUR_CALM);
use Net::HTTP2::nghttp2::Session;
use Test::HTTP2::Frame qw(FRAME_GOAWAY parse_frames);
use Test::HTTP2::Pair qw(new_session_pair pump_sessions);

# Returns ($client, $server, $server_stream_id, $seen, $wire), where $seen
# collects the frames the client's on_frame_recv reports and $wire collects
# every byte the server writes.
sub goaway_pair {
    my ($path) = @_;
    my (@seen, @wire);

    my ($client, $server, undef, $stream_id) = new_session_pair(
        client_callbacks => {
            on_frame_recv => sub {
                my ($frame) = @_;
                push @seen, {%$frame};
                return 0;
            },
        },
        request => {
            method    => 'GET',
            scheme    => 'https',
            authority => 'example.test',
            path      => $path,
        },
    );

    return ($client, $server, $stream_id, \@seen, \@wire);
}

sub goaway_payload {
    my ($wire) = @_;
    my ($frames) = parse_frames(join '', @$wire);
    my @goaway = grep { $_->{type} == FRAME_GOAWAY } @$frames;
    return undef unless @goaway;

    my ($last_stream_id, $error_code) = unpack 'N N',
        substr($goaway[0]{payload}, 0, 8);
    return {
        count          => scalar @goaway,
        last_stream_id => $last_stream_id,
        error_code     => $error_code,
        opaque_data    => substr($goaway[0]{payload}, 8),
    };
}

subtest 'submit_goaway reaches the peer with the given last stream id' => sub {
    my ($client, $server, $stream_id, $seen, $wire) = goaway_pair('/goaway');

    @$seen = ();
    is($server->submit_goaway(last_stream_id => $stream_id), 0,
        'submit_goaway reports acceptance into the outbound queue');
    pump_sessions($client, $server, sub { push @$wire, $_[0] });

    ok(
        scalar(grep { $_->{type} == FRAME_GOAWAY } @$seen),
        'the client received the GOAWAY',
    );

    my $goaway = goaway_payload($wire);
    is($goaway->{count}, 1, 'exactly one GOAWAY went out');
    is($goaway->{last_stream_id}, $stream_id, 'it names the given last stream id');
    is($goaway->{error_code}, NGHTTP2_NO_ERROR, 'it defaults to NO_ERROR');
    is($goaway->{opaque_data}, '', 'it carries no debug data by default');
};

subtest 'opaque_data round-trips' => sub {
    my ($client, $server, $stream_id, $seen, $wire) = goaway_pair('/opaque');

    $server->submit_goaway(
        last_stream_id => $stream_id,
        opaque_data    => 'shutting down',
    );
    pump_sessions($client, $server, sub { push @$wire, $_[0] });

    my $goaway = goaway_payload($wire);
    is($goaway->{opaque_data}, 'shutting down', 'the debug data survives the wire');
    is($goaway->{error_code}, NGHTTP2_NO_ERROR, 'the error code is still NO_ERROR');
};

subtest 'error_code is carried when given' => sub {
    my ($client, $server, $stream_id, $seen, $wire) = goaway_pair('/calm');

    $server->submit_goaway(
        last_stream_id => $stream_id,
        error_code     => NGHTTP2_ENHANCE_YOUR_CALM,
    );
    pump_sessions($client, $server, sub { push @$wire, $_[0] });

    my $goaway = goaway_payload($wire);
    is($goaway->{error_code}, NGHTTP2_ENHANCE_YOUR_CALM,
        'the given error code reaches the peer');
};

subtest 'last_stream_id is required' => sub {
    my ($client, $server, $stream_id, $seen, $wire) = goaway_pair('/required');

    eval { $server->submit_goaway() };
    like($@, qr/submit_goaway: last_stream_id is required/,
        'omitting last_stream_id is refused');
};

subtest 'last_stream_id must be in range' => sub {
    my ($client, $server, $stream_id, $seen, $wire) = goaway_pair('/range');

    eval { $server->submit_goaway(last_stream_id => -1) };
    like($@, qr/submit_goaway: last_stream_id must be an integer in 0 \.\. 0x7FFFFFFF/,
        'a negative last_stream_id is refused');

    eval { $server->submit_goaway(last_stream_id => 2**33) };
    like($@, qr/submit_goaway: last_stream_id must be an integer in 0 \.\. 0x7FFFFFFF/,
        'an oversized last_stream_id is refused');

    is($server->submit_goaway(last_stream_id => 0x7FFFFFFF), 0,
        'the maximum in-range last_stream_id is accepted');

    eval { $server->submit_goaway(last_stream_id => 4) };
    like($@, qr/nghttp2_submit_goaway failed/,
        'an even last_stream_id on a server session still fails the parity check');
};

done_testing;
