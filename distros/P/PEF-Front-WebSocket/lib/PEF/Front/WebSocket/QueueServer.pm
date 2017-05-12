package PEF::Front::WebSocket::QueueServer::Queue;
use strict;
use warnings;
use AnyEvent;
use Scalar::Util qw'weaken refaddr';
use Data::Dumper;

sub new {
	bless {
		queue   => [],
		clients => {},
		id      => $_[1],
		server  => $_[2],
	};
}

sub add_client {
	my ($self, $client, $last_id) = @_;
	my $id_client = $client->id;
	my $lcid      = refaddr $client;
	return if $self->{clients}{$lcid};
	weaken $client;
	$self->{clients}{$lcid} = $client;
	if (defined $last_id and $last_id != 0) {

		if (@{$self->{queue}}) {
			if ($self->{queue}[0][0] <= $last_id) {

# если первое сообщение в очереди имеет айди не выше последнего,
# то у клиента есть как минимум часть актуальной очереди и никаких сообщений не было потеряно
# дошлём клиенту новые сообщения, если они появились
				for my $mt (@{$self->{queue}}) {
					my $id_message = $mt->[0];
					if ($id_message > $last_id) {
						$self->{server}->_transfer($self->{id}, $id_message, $mt->[1], $client->group, [$id_client]);
					}
				}
			} else {
# если айди последнего сообщения клиента "безнадёжно устарел", то ему надо сообщить о необходимости
# перегрузить модель данных
				$self->{server}->_transfer($self->{id}, 0, $self->{server}->reload_message, $client->group, [$id_client]);
			}
		} else {
# если в очереди нет сообщений, значит всё давно заэкспайрилось, клиенту надо перегрузить модель данных
			$self->{server}->_transfer($self->{id}, 0, $self->{server}->reload_message, $client->group, [$id_client]);
		}
	}

# если клиент не показал "последенго айди", то у него только что загруженная модель данных
# return true if client was added
	return 1;
}

sub publish {
	my ($self, $id_message, $message) = @_;
	if ($id_message != 0) {

		# упрядочиваем сообщения по $id_message
		my $last_index = @{$self->{queue}} - 1;
		if (!@{$self->{queue}}
			|| $self->{queue}[$last_index][0] < $id_message)
		{
			push @{$self->{queue}}, [$id_message, $message, time];
		} else {
			if ($self->{queue}[0][0] > $id_message) {
				unshift @{$self->{queue}}, [$id_message, $message, time];
			} else {
				for (my $i = $last_index; $i >= 0; --$i) {
					if ($self->{queue}[$i][0] < $id_message) {
						splice @{$self->{queue}}, $i + 1, 0, [$id_message, $message, time];
						last;
					}
				}
			}
		}
	}
	my %g;
	for (keys %{$self->{clients}}) {
		my $c = $self->{clients}{$_};
		push @{$g{$c->group}}, $c->id;
	}
	for my $group (keys %g) {
		$self->{server}->_transfer($self->{id}, $id_message, $message, $group, $g{$group});
	}
}

sub remove_client {
	my ($self, $client) = @_;
	my $lcid = refaddr $client;
	delete $self->{clients}{$lcid};
	if (!%{$self->{clients}}) {
		weaken $self;
		$self->{destroy_timer} = AnyEvent->timer(
			after => $self->{server}->no_client_expiration,
			cb    => sub {
				if ($self && !%{$self->{clients}}) {
					$self->{server}->_remove_queue($self->{id});
					undef $self;
				}
			}
		);
	}
}

package PEF::Front::WebSocket::QueueServer::Client;
use strict;
use warnings;

sub new {
	bless {
		group  => $_[1],
		id     => $_[2],
		queues => []
	};
}

sub group {
	$_[0]{group};
}

sub id {
	$_[0]{id};
}

sub subscribe {
	my ($self, $queue, $last_id) = @_;
	push @{$self->{queues}}, $queue
		if $queue->add_client($self, $last_id);
}

sub unsubscribe {
	my ($self, $queue) = @_;
	$queue->remove_client($self) if $queue;
}

sub DESTROY {
	$_[0]->unsubscribe($_) for @{$_[0]{queues}};
}

package PEF::Front::WebSocket::QueueServer;
use strict;
use warnings;

use EV;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use CBOR::XS;
use Scalar::Util 'weaken';

sub subscribe_client_to_queue {
	my ($self, $handle, $cmd) = @_;
	my $queue   = $cmd->{queue};
	my $group   = $handle->fh->fileno;
	my $cid     = $cmd->{id_client};
	my $last_id = $cmd->{last_id};
	my $client  = ($self->{groups}{$group}{clients}{$cid} ||= PEF::Front::WebSocket::QueueServer::Client->new($group, $cid));
	my $qo      = $self->{queues}{$queue} || $self->register_queue($queue);
	$client->subscribe($qo, $last_id);
}

sub unsubscribe_client_from_queue {
	my ($self, $handle, $cmd) = @_;
	my $queue  = $cmd->{queue};
	my $group  = $handle->fh->fileno;
	my $cid    = $cmd->{id_client};
	my $client = $self->{groups}{$group}{clients}{$cid};
	my $qo     = $self->{queues}{$queue};
	$client->unsubscribe($qo) if $client && $qo;
}

sub publish_to_queue {
	my ($self, $handle, $cmd) = @_;
	my $queue      = $cmd->{queue};
	my $id_message = $cmd->{id_message};
	my $message    = $cmd->{message};
	my $qo         = $self->{queues}{$queue} || $self->register_queue($queue);
	$qo->publish($id_message, $message);
}

sub unregister_client {
	my ($self, $handle, $cmd) = @_;
	my $group = $handle->fh->fileno;
	my $cid   = $cmd->{id_client};
	delete $self->{groups}{$group}{clients}{$cid};
}

my %cmd_switch = (
	subscribe   => \&subscribe_client_to_queue,
	unsubscribe => \&unsubscribe_client_from_queue,
	publish     => \&publish_to_queue,
	unregister  => \&unregister_client,
);

sub on_cmd {
	my ($self, $handle, $cmd) = @_;
	my $group = $handle->fh->fileno;
	$handle->push_read(
		cbor => sub {
			$self->on_cmd(@_);
		}
	);
	if (my $cmd_sub = $cmd_switch{$cmd->{command}}) {
		$cmd_sub->($self, $handle, $cmd);
	}
}

sub register_queue {
	my ($self, $queue) = @_;
	$self->{queues}{$queue} = PEF::Front::WebSocket::QueueServer::Queue->new($queue, $self);
	$self->{queues}{$queue};
}

sub create_group {
	my ($self, $group, $handle) = @_;
	$self->{groups}{$group} = {
		handle  => $handle,
		clients => {}
	};
}

sub destroy_group {
	my ($self, $group) = @_;
	delete $self->{groups}{$group};
}

sub _remove_queue {
	my ($self, $queue) = @_;
	delete $self->{queues}{$queue};
}

sub _transfer {
	my ($self, $queue, $id_message, $message, $group, $cidref) = @_;
	my $handle = $self->{groups}{$group}{handle};
	$handle->push_write(cbor => [$queue, $id_message, $message, $cidref]);
}

sub on_disconnect {
	my ($self, $handle, $fatal, $msg) = @_;
	$self->destroy_group($handle->fh->fileno);
	$handle->destroy;

}

sub on_accept {
	my ($self, $fh, $host, $port) = @_;
	my $handle = AnyEvent::Handle->new(
		on_error => sub {$self->on_disconnect(@_)},
		on_eof   => sub {$self->on_disconnect(@_)},
		fh       => $fh,
	);
	$self->create_group($fh->fileno, $handle);
	$handle->push_read(
		cbor => sub {
			$self->on_cmd(@_) if $self;
		}
	);
}

sub new {
	my ($class, %args) = @_;
	my $self;
	my $tcp_address          = delete $args{address}              || '127.0.0.1';
	my $tcp_port             = delete $args{port}                 || 54321;
	my $no_client_expiration = delete $args{no_client_expiration} || 900;
	my $message_expiration   = delete $args{message_expiration}   || 3600;
	my $reload_message       = delete $args{reload_message}       || {result => 'RELOAD'};
	$self = {
		server               => tcp_server($tcp_address, $tcp_port, sub {$self->on_accept(@_)}),
		no_client_expiration => $no_client_expiration,
		message_expiration   => $message_expiration,
		reload_message       => $reload_message,
		groups               => {},
		queues               => {}
	};
	bless $self, $class;
}

sub no_client_expiration {
	$_[0]{no_client_expiration};
}

sub message_expiration {
	$_[0]{message_expiration};
}

sub reload_message {
	$_[0]{reload_message};
}

use Data::Dumper;

sub run {
	my ($slave, $tcp_address, $tcp_port, $no_client_expiration, $message_expiration, $reload_message) = @_;
	if ($reload_message) {
		$reload_message = decode_cbor $reload_message;
		if (!%$reload_message) {
			$reload_message = undef;
		}
	}
	my $queue_server = new PEF::Front::WebSocket::QueueServer(
		address              => $tcp_address,
		port                 => $tcp_port,
		no_client_expiration => $no_client_expiration,
		message_expiration   => $message_expiration,
		reload_message       => $reload_message
	);
	my $handle = AnyEvent::Handle->new(
		on_error => sub {
			exit;
		},
		on_eof => sub {
			exit;
		},
		on_read => sub {
		},
		fh => $slave,
	);
	$handle->push_write("1");
	EV::run();
}

1;
