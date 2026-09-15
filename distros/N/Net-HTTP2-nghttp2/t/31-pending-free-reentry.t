use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Net::HTTP2::nghttp2::Session;
use Test::HTTP2::Frame qw(FRAME_HEADERS);
use Test::HTTP2::Pair qw(new_session_pair pump_sessions);

# Releasing a data provider drops the last reference to its callback_data, so
# that object's DESTROY runs - arbitrary Perl - in the middle of the drain that
# frees the providers released during a session call. A DESTROY that flushes
# the session re-enters the drain. The drain must take the list off the session
# before it frees anything, or the nested drain walks the same entries and
# frees every one of them a second time.

{
    package Test::Flushing::Guard;

    sub new {
        my ($class, %args) = @_;
        return bless { %args }, $class;
    }

    sub DESTROY {
        my ($self) = @_;
        return if $self->{destroyed}++;
        $self->{on_destroy}->($self->{stream_id});
        return;
    }
}

sub request_args {
    my ($path) = @_;
    return {
        method    => 'GET',
        scheme    => 'https',
        authority => 'example.test',
        path      => $path,
    };
}

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

my @server_streams;
my @destroyed;
my $server;

my %client_body;

my ($client, $session) = new_session_pair(
    server_callbacks => {
        on_frame_recv => sub {
            my ($frame) = @_;
            push @server_streams, $frame->{stream_id}
                if $frame->{type} == FRAME_HEADERS && $frame->{stream_id} > 0;
            return 0;
        },
    },
    client_callbacks => {
        on_data_chunk_recv => sub {
            my ($stream_id, $data) = @_;
            $client_body{$stream_id} .= $data;
            return 0;
        },
    },
);
$server = $session;

$client->submit_request(%{ request_args('/one') });
$client->submit_request(%{ request_args('/two') });
pump_sessions($client, $server);

is(scalar @server_streams, 2, 'the server received both requests');

# Two streamed responses submitted together close inside the same session
# send, so both providers are on the pending list when the drain starts.
for my $stream_id (@server_streams) {
    my $sent = 0;
    $server->submit_response(
        $stream_id,
        status        => 200,
        body          => sub { return ('', 1) if $sent++; return ('body', 1) },
        callback_data => Test::Flushing::Guard->new(
            stream_id  => $stream_id,
            on_destroy => sub {
                my ($id) = @_;
                push @destroyed, $id;
                # A guard object that flushes the connection on the way out.
                eval { $server->mem_send; 1 };
                return;
            },
        ),
    );
}
pump_sessions($client, $server);

is_deeply([sort { $a <=> $b } @destroyed], [sort { $a <=> $b } @server_streams],
    'each callback_data guard was released exactly once');
is_deeply(\@warnings, [], 'the nested flush did not free anything twice');

# The session survives the re-entrant drain and still serves a new stream.
my $third_client_stream = $client->submit_request(%{ request_args('/three') });
pump_sessions($client, $server);
is(scalar @server_streams, 3, 'the server received a third request');
$server->submit_response($server_streams[-1], status => 200, body => 'third');
pump_sessions($client, $server);
is($client_body{$third_client_stream}, 'third',
    'the session still serves a stream after the nested drain');

done_testing;
