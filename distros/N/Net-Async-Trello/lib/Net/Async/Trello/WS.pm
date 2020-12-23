package Net::Async::Trello::WS;

use strict;
use warnings;

our $VERSION = '0.006'; # VERSION

use parent qw(IO::Async::Notifier);

use Syntax::Keyword::Try;

use JSON::MaybeXS;
use Net::Async::WebSocket::Client;

use Log::Any qw($log);

my $json = JSON::MaybeXS->new;

sub configure {
	my ($self, %args) = @_;
	for my $k (grep exists $args{$_}, qw(token trello)) {
		$self->{$k} = delete $args{$k};
	}
	$self->SUPER::configure(%args);
}

sub connection {
    my ($self, %args) = @_;
    $self->{ws_connection} ||= do {
        $log->tracef('Set up WS connection');
        my $uri = $self->trello->endpoint(
            'websockets',
            token => $self->token,
        );
        $log->tracef('Connecting to websocket endpoint %s', "$uri");
        $self->{ws}->connect(
            url        => $uri,
            host       => $uri->host,
            (
                $uri->scheme eq 'wss'
                ? (
                    SSL_hostname => $uri->host,
                ) : ()
            )
        )->then(sub {
            my ($conn) = @_;
            $log->tracef("Connected");
            # $conn->send_frame($json->encode({"type"=> "ping","reqid"=>0}));
            Future->done($conn);
        });
    };
}

my %model_for_type = (
    board => 'Board',
    card => 'Card'
);

sub next_request_id {
    return (shift->{last_request_id} //= 0)++;
}

sub subscribe {
    my ($self, $type, $id) = @_;
    $self->connection->then(sub {
        my ($conn) = @_;
        $log->tracef("Subscribing to %s %s", $type, $id);
        my $src = $self->{update_channel}{$id} //= $self->ryu->source;
        $conn->send_frame(
            buffer => $json->encode({
                idModel          => $id,
                invitationTokens => [],
                modelType        => $model_for_type{$type},
                reqid            => $self->next_request_id,
                tags             => [qw(clientActions updates)],
                type             => "subscribe",
            }),
            masked => 1
        );
        return Future->done($src);
    })
}

sub websocket_events { my ($self) = @_; $self->{websocket_events} //= $self->ryu->source }

sub on_frame {
	my ($self, $ws, $bytes) = @_;
    my $text = $bytes; # Encode::decode_utf8($bytes);
    $log->debugf("Have frame [%s]", $text);
    $self->websocket_events->emit($text);

    if(length $text) {
        $log->tracef("<< %s", $text);
        try {
            my $data = $json->decode($text);
            if(my $chan = $data->{idModelChannel}) {
                $log->tracef("Notification for [%s] - %s", $chan, $data);
                $self->{update_channel}{$chan}->emit($data->{notify});
            } else {
                $log->warnf("No idea what %s is", $data);
            }
        } catch {
            $log->errorf("Exception in websocket raw frame handling: %s (original text %s)", $@, $text);
        }
    } else {
        $log->tracef("<< ping received, responding");
        # Empty frame is used for PING, send a response back
        $self->pong;
    }
}

sub pong {
    my ($self) = @_;
    $self->{ws}->send_frame(
        masked => 1,
        buffer => ''
    );
}

sub _add_to_loop {
    my ($self, $loop) = @_;

    $self->add_child(
        $self->{ryu} = Ryu::Async->new
    );

    $self->add_child(
        $self->{ws} = Net::Async::WebSocket::Client->new(
            on_frame => $self->curry::weak::on_frame,
        )
    );
    if(0) {
        $self->add_child(
            my $timer = IO::Async::Timer::Periodic->new(
                interval => 15,
                on_tick => $self->curry::weak::on_tick,
            )
        );
        $timer->start;
        Scalar::Util::weaken($self->{timer} = $timer);
    }
}

sub on_tick {
    my ($self) = @_;
    my $ws = $self->connection;
    return unless $ws->is_ready;
    $self->pong;
}

sub trello { shift->{trello} }
sub token { shift->{token} }

sub ryu { shift->trello->ryu(@_) }

1;

