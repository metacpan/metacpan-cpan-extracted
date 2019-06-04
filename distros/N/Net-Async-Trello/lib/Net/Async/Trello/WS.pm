package Net::Async::Trello::WS;

use strict;
use warnings;

our $VERSION = '0.005'; # VERSION

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
        my $uri = $self->trello->endpoint(
            'websockets',
            token => $self->token,
        );
        $self->{ws}->connect(
            url        => $uri,
            host       => $uri->host,
            ($uri->scheme eq 'wss'
            ? (
                service      => 443,
                extensions   => [ qw(SSL) ],
                SSL_hostname => $uri->host,
            ) : (
                service    => 80,
            ))
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

sub subscribe {
    my ($self, $type, $id) = @_;
    $self->connection->then(sub {
        my ($conn) = @_;
        $log->tracef("Subscribing to %s %s", $type, $id);
        $conn->send_frame(
            buffer => $json->encode({
                idModel          => $id,
                invitationTokens => [],
                modelType        => $model_for_type{$type},
                reqid            => 1,
                tags             => [qw(clientActions updates)],
                type             => "subscribe",
            }),
            masked => 1
        );
    })
}

sub on_frame {
	my ($self, $ws, $bytes) = @_;
    my $text = Encode::decode_utf8($bytes);
    $log->debugf("Have frame [%s]", $text);

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
        # Empty frame is used for PING, send a response back
        $self->pong;
    }
}

sub pong {
    my ($self) = @_;
    $self->{ws}->send_frame('');
}

sub next_request_id {
    ++shift->{request_id}
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
    $self->add_child(
        my $timer = IO::Async::Timer::Periodic->new(
            interval => 15,
            on_tick => $self->curry::weak::on_tick,
        )
    );
    $timer->start;
    Scalar::Util::weaken($self->{timer} = $timer);
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

