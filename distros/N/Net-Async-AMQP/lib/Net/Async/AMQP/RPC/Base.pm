package Net::Async::AMQP::RPC::Base;
$Net::Async::AMQP::RPC::Base::VERSION = '2.000';
use strict;
use warnings;

use parent qw(IO::Async::Notifier);

=head1 NAME

Net::Async::AMQP::RPC::Base - base class for client and server RPC handling

=head1 VERSION

version 2.000

=head1 DESCRIPTION

This is used internally by L<Net::Async::AMQP::RPC::Server> and 
L<Net::Async::AMQP::RPC::Client>, see those classes for details.

=cut

use Net::Async::AMQP;

use Variable::Disposition qw(retain_future);
use Log::Any qw($log);
use Scalar::Util ();

=head2 mq

Returns the L<Net::Async::AMQP> instance.

=cut

sub mq {
	my $self = shift;
	return $self->{mq} if $self->{mq};
	$log->debugf("Establishing connection to MQ server at %s:%s", $self->{host}, $self->{port});
	$self->add_child(
		$self->{mq} = my $mq = Net::Async::AMQP->new
	);
	$mq->connect(
		host  => $self->{host},
		user  => $self->{user},
		pass  => $self->{pass},
		port  => $self->{port},
		vhost => $self->{vhost},
		client_properties => {
			capabilities => {
				'consumer_cancel_notify' => Net::AMQP::Value->true,
			},
		},
	);
	$mq
}

=head2 queue_name

Returns a L<Future> which resolves to the queue name once the queue has been declared.

=cut

sub queue_name {
	$_[0]->{queue_name} ||= $_[0]->future(set_label => 'queue name')->on_done(sub {
		$log->infof("Queue name is %s", shift);
	})
}

=head2 routing_key

The routing key used for publishing. Defaults to the empty string.

=cut

sub routing_key { '' }

=head2 exchange

The exchange messages should be published to (or queues bound to).

=cut

sub exchange { shift->{exchange} }

=head2 future

Helper method for instantiating a L<Future>.

=cut

sub future { my $self = shift; $self->mq->future(@_) }

=head2 _add_to_loop

Called when this instance is added to a L<IO::Async::Loop>. Requires both an
L</mq> instance and a valid L</exchange> name.

=cut

sub _add_to_loop {
	my ($self, $loop) = @_;
	die "Need an MQ connection" unless $self->mq;
	die "Need an exchange name" unless defined $self->{exchange};
	retain_future(
		$self->connected->then(sub {
			$log->debug("Connected to MQ server, activating consumer");
			$self->consumer
		})->then(sub {
			$log->info("Ready for requests");
			$self->active->done
		})->on_fail(sub {
			$log->errorf("Failure: %s", shift);
		})
	)
}

=head2 connected

Returns a L<Future> which resolves once the underlying L<Net::Async::AMQP> connection
is established.

=cut

sub connected { shift->mq->connected }

=head2 client_queue

Sets up a queue for an RPC client.

=cut

sub client_queue {
	my $self = shift;
	$self->{client_queue} ||= $self->consumer_channel->then(sub {
		my ($ch) = @_;
		$log->debug("Declaring queue");
		$ch->queue_declare(
			queue => $self->{queue} // '',
		)->then(sub {
			my ($q) = @_;
			$self->queue_name->done($q->queue_name);
			Future->done($q)
		})
	})->on_fail(sub {
		$log->errorf("Failed to set up client queue: %s", shift)
	})
}

=head2 server_queue

Sets up a queue for an RPC server.

=cut

sub server_queue {
	my $self = shift;
	$self->{server_queue} ||= $self->consumer_channel->then(sub {
		my ($ch) = @_;
		$log->debug("Declaring queue");
		Future->needs_all(
			$ch->queue_declare(
				queue => $self->{queue} // '',
			),
			$ch->exchange_declare(
				exchange    => $self->{exchange},
				type        => 'topic',
			)
		)->then(sub {
			my ($q) = @_;
			$self->queue_name->done($q->queue_name);
			$log->debugf("Binding queue %s to exchange %s", $q->queue_name, $self->{exchange});
			$q->bind_exchange(
				channel     => $ch,
				exchange    => $self->{exchange},
				routing_key => $self->{routing_key} // '',
			)->transform(
				done => sub { $q }
			)
		})
	})->on_fail(sub {
		$log->errorf("Failed to set up server queue: %s", shift)
	})
}

=head2 reply

Publishes a reply to an RPC message.

Expects the following:

=over 4

=item * reply_to - which queue to deliver to

=item * correlation_id - the ID to use for this message

=item * type - message type

=item * payload - message content

=item * content_type - what's in the message

=item * content_encoding - any encoding layers

=back

=cut

sub reply {
	my ($self, %args) = @_;
	$self->publisher_channel->then(sub {
		my ($ch) = @_;
		$ch->publish(
			exchange         => '',
			routing_key      => $args{reply_to},
			delivery_mode    => 2, # persistent
			correlation_id   => $args{correlation_id},
			type             => $args{type},
			payload          => $args{payload},
			content_type     => $args{content_type} // 'application/binary',
			content_encoding => $args{content_encoding},
		)
	});
}

=head2 consumer

Activates a consumer. Resolves when the consumer is running.

=cut

sub consumer {
	my $self = shift;
	$self->{consumer} ||= Future->needs_all(
		$self->queue,
		$self->consumer_channel
	)->then(sub {
		my ($q, $ch) = @_;
		$log->debug("Starting consumer");
		$q->consumer(
			channel => $ch,
			ack => 1,
			on_message => $self->curry::weak::on_message($ch),
		)
	})->on_fail(sub {
		$log->errorf("Failed to set up consumer: %s", shift)
	})
}

=head2 on_message

Called when there's a message. Receives the L<Net::Async::AMQP::Channel> followed by some named parameters:

=over 4

=item * type

=item * payload - scalar containing the raw binary data for this message

=item * consumer_tag - which consumer tag received this message

=item * delivery_tag - the delivery information for L<Net::Async::AMQP::Channel/ack>

=item * routing_key - routing key used for this message

=item * properties - any properties for the message

=item * headers - custom headers

=back

See L<Net::Async::AMQP::Queue/consumer> for more details (including the contents of C<properties> and C<headers>).

=cut

sub on_message {
	my ($self, $ch, %args) = @_;
	# { my %x = %{$args{properties}}; $log->debugf("have: %s", join ',', map { $_ . '=' . $x{$_} } sort keys %x); }
	$log->debugf("Received message of type %s, correlation ID %s, reply_to %s", $args{type}, $args{properties}{correlation_id}, $args{properties}{reply_to});
	my $dtag = $args{delivery_tag};
	(eval {
		my $f = $self->process_message(
			type         => $args{type},
			id           => $args{properties}{correlation_id},
			reply_to     => $args{properties}{reply_to},
			payload      => $args{payload},
			content_type => $args{properties}{content_type},
			user_id      => $args{properties}{user_id},
		);
		$f = Future->done($f) unless Scalar::Util::blessed($f) && $f->isa('Future');
		$f
	} or do {
		my $err = $@;
		$log->errorf("Error processing: %s", $err);
		Future->fail($err);
	})->on_ready(sub {
		$self->{pending}{$dtag} = $ch->ack(
			delivery_tag => $dtag
		)->on_ready(sub {
			delete $self->{pending}{$dtag}
		});
	})
}

=head2 process_message

Abstract method for message processing. Will receive the following named parameters:

The base implementation here will raise an exception. Override this in your subclass
to do something more useful.

=cut

sub process_message { die 'abstract method ->process_message called - please subclass and override' }

=head2 consumer_channel

Returns a L<Future> which resolves to the L<Net::Async::AMQP::Channel> used for the consumer.

=cut

sub consumer_channel {
	my $self = shift;
	$self->{consumer_channel} ||= $self->connected->then(sub {
		$self->mq->open_channel
	})->on_done(sub {
		$log->debugf("Receiver channel ID %d", shift->id);
	})
}

=head2 publisher_channel

Returns a L<Future> which resolves to the L<Net::Async::AMQP::Channel> used for the publisher.

=cut

sub publisher_channel {
	my $self = shift;
	$self->{consumer_channel} ||= $self->connected->then(sub {
		$self->mq->open_channel
	})->on_done(sub {
		$log->debugf("Sender channel ID %d", shift->id);
	})
}

=head2 active

Returns a L<Future> which resolves when the underlying MQ connection is ready for use.

=cut

sub active {
	my $self = shift;
	$self->{active} ||= $self->mq->future
}

sub configure {
	my ($self, %args) = @_;
	for (qw(mq user pass host port vhost mq queue exchange)) {
		$self->{$_} = delete $args{$_} if exists $args{$_}
	}
	$self->SUPER::configure(%args)
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Licensed under the same terms as Perl itself, with additional licensing
terms for the MQ spec to be found in C<share/amqp0-9-1.extended.xml>
('a worldwide, perpetual, royalty-free, nontransferable, nonexclusive
license to (i) copy, display, distribute and implement the Advanced
Messaging Queue Protocol ("AMQP") Specification').
