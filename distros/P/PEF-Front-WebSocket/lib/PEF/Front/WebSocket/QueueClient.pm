package PEF::Front::WebSocket::QueueClient;
use strict;
use warnings;

use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;
use CBOR::XS;
use Scalar::Util qw'weaken refaddr';

sub publish {
	my ($self, $queue, $id_message, $message) = @_;
	$self->{handle}->push_write(
		cbor => {
			command    => 'publish',
			queue      => $queue,
			id_message => $id_message,
			message    => $message,
		}
	);
}

sub subscribe {
	my ($self, $queue, $client, $last_id) = @_;
	my $id_client = refaddr $client;
	return if exists $self->{queues}{$queue}{$id_client};
	$self->{queues}{$queue}{$id_client} = undef;
	$self->{clients}{$id_client} = $client;
	$self->{handle}->push_write(
		cbor => {
			command   => 'subscribe',
			queue     => $queue,
			id_client => $id_client,
			last_id   => $last_id,
		}
	);
}

sub unsubscribe {
	my ($self, $queue, $client) = @_;
	my $id_client = refaddr $client;
	return if not exists $self->{queues}{$queue}{$id_client};
	$self->{queues}{$queue}{$id_client} = undef;
	$self->{handle}->push_write(
		cbor => {
			command   => 'unsubscribe',
			queue     => $queue,
			id_client => $id_client,
		}
	);
}

sub unregister_client {
	my ($self, $client) = @_;
	my $id_client = refaddr $client;
	return if not $self->{clients}{$id_client};
	delete $self->{clients}{$id_client};
	for my $queue (keys %{$self->{queues}}) {
		delete $self->{queues}{$queue}{$id_client};
	}
	$self->{handle}->push_write(
		cbor => {
			command   => 'unregister',
			id_client => $id_client,
		}
	);
}

sub on_disconnect {
	my ($self, $handle, $fatal, $msg) = @_;
	for my $cid (keys %{$self->{clients}}) {
		my $client = $self->{clients}{$cid};
		$client->on_queue_error('disconnect');
	}
	delete $self->{handle};
	delete $self->{tcp_guard};
	delete $self->{clients};
	delete $self->{queues};
}

sub on_queue {
	my ($self, $handle, $cmd) = @_;
	$handle->push_read(
		cbor => sub {
			$self->on_queue(@_);
		}
	);
	my ($queue, $id_message, $message, $cidref) = @$cmd;
	for my $cid (@$cidref) {
		my $client = $self->{clients}{$cid};
		if (exists $self->{queues}{$queue}{$cid}) {
			$client->on_queue($queue, $id_message, $message);
		}
	}
}

sub new {
	my ($class, %args) = @_;
	my $tcp_address = delete $args{address} || '127.0.0.1';
	my $tcp_port    = delete $args{port}    || 54321;
	my $self;
	my $cv = AnyEvent->condvar();
	$self = {
		address   => $tcp_address,
		port      => $tcp_port,
		tcp_guard => tcp_connect(
			$tcp_address,
			$tcp_port,
			sub {
				my ($fh) = @_;
				$self->{handle} = AnyEvent::Handle->new(
					fh       => $fh,
					on_eof   => sub {$self->on_disconnect(@_)},
					on_error => sub {$self->on_disconnect(@_)},
				);
				$self->{handle}->push_read(cbor => sub {$self->on_queue(@_)});
				$cv->send;
			}
		),
		clients => {},
		queues  => {}
	};
	bless $self, $class;
	$cv->recv;
	$self;
}

1;
