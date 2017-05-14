package Net::Async::Trello::WS;
$Net::Async::Trello::WS::VERSION = '0.001';
use strict;
use warnings;

use parent qw(IO::Async::Notifier);

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
        my $uri = $self->endpoint(
            'websockets',
            token => $self->ws_token,
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
        shift->send_frame(
            $json->encode({
                idModel          => $id,
                invitationTokens => [],
                modelType        => $model_for_type{$type},
                reqid            => 1,
                tags             => [qw(clientActions updates)],
                type             => "subscribe",
            })
        );
        Future->done;
    })
}

{
my %types = reverse %Protocol::WebSocket::Frame::TYPES;
sub on_raw_frame {
	my ($self, $ws, $frame, $bytes) = @_;
    my $text = Encode::decode_utf8($bytes);
    $log->debugf("Have frame opcode %d type %s with bytes [%s]", $frame->opcode, $types{$frame->opcode}, $text);

    # Empty frame is used for PING, send a response back
    if($frame->opcode == 1) {
        if(!length($bytes)) {
            $ws->send_frame('');
        } else {
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
        }
    }
}
}

sub on_frame {
	my ($self, $ws, $text) = @_;
    $log->debugf("Have WS frame [%s]", $text);
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
            on_raw_frame => $self->curry::weak::on_raw_frame,
            on_frame     => sub { },
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
    $ws->then(sub { shift->send_frame('') })
}

sub trello { shift->{trello} }

sub ryu { shift->trello->ryu(@_) }

1;

