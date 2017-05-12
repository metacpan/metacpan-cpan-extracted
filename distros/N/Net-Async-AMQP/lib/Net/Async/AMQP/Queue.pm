package Net::Async::AMQP::Queue;
$Net::Async::AMQP::Queue::VERSION = '2.000';
use strict;
use warnings;

=head1 NAME

Net::Async::AMQP::Queue - deal with queue-specific functionality

=head1 VERSION

version 2.000

=cut

use Future;
use curry::weak;
use Class::ISA ();
use Scalar::Util qw(weaken);
use Variable::Disposition qw(retain_future);

use Net::Async::AMQP;

=head1 METHODS

=cut

=head2 listen

Starts a consumer on this queue.

 $q->listen(
  channel => $ch,
  ack => 1
 )->then(sub {
  my ($q, $ctag) = @_;
  print "Queue $q has ctag $ctag\n";
  ...
 })

Expects the following named parameters:

=over 4

=item * channel - which channel to listen on

=item * ack (optional) - true to enable ACKs

=item * consumer_tag (optional) - specific consumer tag

=back

Returns a L<Future> which resolves with ($queue, $consumer_tag) on
completion. If this is cancelled before we receive the Basic.ConsumeOk
acknowledgement from the server, we'll issue an explicit cancel.

=cut

sub listen {
    my $self = shift;
    my %args = @_;

	my $ch = delete $args{channel} or die "No channel provided";
	$self->{channel} = $ch;

    # Attempt to bind after we've successfully declared the exchange.
    retain_future($self->future->then(sub {
        my $f = $ch->loop->new_future->set_label("listen on " . $self->queue_name);
        $ch->debug_printf("Attempting to listen for events on queue [%s]", $self->queue_name);

        my $frame = Net::AMQP::Protocol::Basic::Consume->new(
            queue        => Net::AMQP::Value::String->new($self->queue_name),
            consumer_tag => (exists $args{consumer_tag} ? Net::AMQP::Value::String->new($args{consumer_tag}) : ''),
            no_local     => 0,
            no_ack       => ($args{ack} ? 0 : 1),
            exclusive    => 0,
            ticket       => 0,
            nowait       => 0,
        );
        $ch->push_pending(
            'Basic::ConsumeOk' => (sub {
                my ($amqp, $frame) = @_;
				my $ctag = $frame->method_frame->consumer_tag;
				$ch->bus->invoke_event(
					listener_start => $ctag
				);
                $f->done($self => $ctag) unless $f->is_ready;

				# If we were cancelled before we received the OK response,
				# that's mildly awkward - we need to cancel the consumer,
				# note that messages may be delivered in the interim.
				if($f->is_cancelled) {
					retain_future(
						$self->cancel(
							consumer_tag => $ctag
						)->on_fail(sub {
							# We should report this, but where to?
							$ch->debug_printf("Failed to cancel listener %s", $ctag);
						})->set_label(
							"Cancel $ctag"
						)
					)
				}
            })
        );
		$ch->closure_protection($f);
        $ch->send_frame($frame);
        $f;
    }));
}

=head2 cancel

Cancels the given consumer.

 $q->cancel(
  consumer_tag => '...',
 )->then(sub {
  my ($q, $ctag) = @_;
  print "Queue $q ctag $ctag cancelled\n";
  ...
 })

Expects the following named parameters:

=over 4

=item * consumer_tag (optional) - specific consumer tag

=back

Returns a L<Future> which resolves with ($queue, $consumer_tag) on
completion.

=cut

sub cancel {
    my $self = shift;
    my %args = @_;
	my $ch = delete $self->{channel} or die "No channel";
	my $ctag = delete $args{consumer_tag} or die "No ctag";

    # Attempt to bind after we've successfully declared the exchange.
	retain_future($self->future->then(sub {
		my $f = $ch->loop->new_future->set_label("cancel ctag " . $ctag);
		$ch->debug_printf("Attempting to cancel consumer [%s]", $ctag);

		my $frame = Net::AMQP::Protocol::Basic::Cancel->new(
			consumer_tag => Net::AMQP::Value::String->new($ctag),
			nowait       => 0,
		);
		$ch->push_pending(
			'Basic::CancelOk' => (sub {
				my ($amqp, $frame) = @_;
				my $ctag = $frame->method_frame->consumer_tag;
				$ch->bus->invoke_event(
					listener_stop => $ctag
				);
				$f->done($self => $ctag) unless $f->is_cancelled;
			})
		);
		$ch->closure_protection($f);
		$ch->send_frame($frame);
		$f;
	}));
}

=head2 consumer

Similar to L</listen>, but applies the event handlers so you can just provide an C<on_message> callback.

Takes the following extra named parameters:

=over 4

=item * on_message - callback for message handling

=item * on_cancel - will be called if the consumer is cancelled (either by the server or client)

=back

For server consumer cancellation notification, you'll need consumer_cancel_notifications:

 $mq->connect(
  ...
  client_properties => {
   capabilities => {
    'consumer_cancel_notify' => Net::AMQP::Value->true
   },
  },
 )

The on_message callback receives the following named parameters:

=over 4

=item * type

=item * payload - scalar containing the raw binary data for this message

=item * consumer_tag - which consumer tag received this message

=item * delivery_tag - the delivery information for L<Net::Async::AMQP::Channel/ack>

=item * routing_key - routing key used for this message

=item * properties - any properties for the message

=item * headers - custom headers

=back

Properties include:

=over 4

=item * correlation_id - user-specified ID that can be used to link related messages, see
L<Net::Async::RPC::Client> for details.

=item * reply_to - user-specified target queue to which any replies should be sent

=item * content_type - payload format

=item * content_encoding - any encoding applied to the payload (gzip etc.)

=item * delivery_mode - delivery persistence - 1 for default, 2 for permanent

=item * priority - message priority, ranges from 0..255

=item * expiration - when this message (would have) expired

=item * message_id - user-specified ID

=item * timestamp - when the message was published, usually the time in seconds

=item * user_id - custom user-id info

=item * app_id - user-specified application information

=back

See C<examples/alternative-consumer.pl> for a usage example.

=cut

sub consumer {
    my ($self, %args) = @_;

	my $ch = (delete $args{channel}) // die "No channel";
	my $ctag = (delete $args{consumer_tag}) // '';
	my $on_message = delete $args{on_message} || sub { };
	my $on_cancel = delete $args{on_cancel} || sub { };
	my @ev;
	$ch->bus->subscribe_to_event(
		@ev = (
			# Deliver any matching messages to our callback
			message => sub {
				my ($ev, $type, $payload, $incoming_ctag, $dtag, $rkey, $headers, $properties) = @_;
				return unless $incoming_ctag eq $ctag;
				$on_message->(
					type => $type,
					payload => $payload,
					consumer_tag => $ctag,
					delivery_tag => $dtag,
					routing_key => $rkey,
					headers => $headers,
					properties => $properties,
				);
			},
			# Drop event handlers and call cancellation callback on cancel
			cancel => sub {
				my ($ev, %args) = @_;
				return unless $args{ctag} eq $ctag;
				# Avoid potential race between ->cancel and the consumer future being cancelled
				eval {
					$ch->bus->unsubscribe_from_events(@ev);
				};
				$on_cancel->(
					consumer_tag => $ctag
				);
			}
		)
	);
	$self->listen(
		%args,
		channel => $ch,
		consumer_tag => $ctag,
	)->on_done(sub {
		$ctag = $_[1];
	})->on_ready(sub {
		return if shift->is_done;
		eval {
			$ch->bus->unsubscribe_from_events(@ev);
		};
		$on_cancel->(
			consumer_tag => $ctag
		)
	});
}

=head2 bind_exchange

Binds this queue to an exchange.

 $q->bind_exchange(
  channel => $ch,
  exchange => '',
 )->then(sub {
  my ($q) = @_;
  print "Queue $q bound to default exchange\n";
  ...
 })

Expects the following named parameters:

=over 4

=item * channel - which channel to perform the bind on

=item * exchange - the exchange to bind, can be '' for default

=item * routing_key (optional) - a routing key for the binding

=back

Returns a L<Future> which resolves with ($queue) on
completion.

=cut

sub bind_exchange {
    my $self = shift;
    my %args = @_;
    die "No exchange specified" unless exists $args{exchange};
	my $ch = delete $args{channel} or die "No channel provided";

    # Attempt to bind after we've successfully declared the exchange.
	retain_future($self->future->then(sub {
		my $f = $ch->loop->new_future->set_label(sprintf "bind exchange [%s] to exchange [%s] with rkey [%s]", $self->queue_name, $args{exchange}, $args{routing_key} // '(none)');
		$ch->debug_printf("Binding queue [%s] to exchange [%s] with rkey [%s]", $self->queue_name, $args{exchange}, $args{routing_key} // '(none)');

		my $frame = Net::AMQP::Frame::Method->new(
			method_frame => Net::AMQP::Protocol::Queue::Bind->new(
				queue       => Net::AMQP::Value::String->new($self->queue_name),
				exchange    => Net::AMQP::Value::String->new($args{exchange}),
				(exists($args{routing_key}) ? ('routing_key' => Net::AMQP::Value::String->new($args{routing_key})) : ()),
				ticket      => 0,
				nowait      => 0,
			)
		);
		$ch->push_pending(
			'Queue::BindOk' => [ $f, $self ],
		);
		$ch->closure_protection($f);
		$ch->send_frame($frame);
		$f
	}));
}

=head2 unbind_exchange

Unbinds this queue from an exchange.

 $q->unbind_exchange(
  channel => $ch,
  exchange => '',
 )->then(sub {
  my ($q) = @_;
  print "Queue $q unbound from default exchange\n";
  ...
 })

Expects the following named parameters:

=over 4

=item * channel - which channel to perform the bind on

=item * exchange - the exchange to bind, can be '' for default

=item * routing_key (optional) - a routing key for the binding

=back

Returns a L<Future> which resolves with ($queue) on
completion.

=cut

sub unbind_exchange {
    my $self = shift;
    my %args = @_;
    die "No exchange specified" unless exists $args{exchange};
	my $ch = delete $args{channel} or die "No channel provided";

    # Attempt to unbind after we've successfully declared the exchange.
	retain_future($self->future->then(sub {
		my $f = $ch->loop->new_future->set_label("unbind exchange [%s] from exchange [%s] with rkey [%s]", $self->queue_name, $args{exchange}, $args{routing_key} // '(none)');
		$ch->debug_printf("Unbinding queue [%s] from exchange [%s] with rkey [%s]", $self->queue_name, $args{exchange}, $args{routing_key} // '(none)');

		my $frame = Net::AMQP::Frame::Method->new(
			method_frame => Net::AMQP::Protocol::Queue::Unbind->new(
				queue       => Net::AMQP::Value::String->new($self->queue_name),
				exchange    => Net::AMQP::Value::String->new($args{exchange}),
				(exists($args{routing_key}) ? ('routing_key' => Net::AMQP::Value::String->new($args{routing_key})) : ()),
				ticket      => 0,
				nowait      => 0,
			)
		);
		$ch->push_pending(
			'Queue::UnbindOk' => [ $f, $self ],
		);
		$ch->closure_protection($f);
		$ch->send_frame($frame);
		$f
	}));
}

=head2 delete

Deletes this queue.

 $q->delete(
  channel => $ch,
 )->then(sub {
  my ($q) = @_;
  print "Queue $q deleted\n";
  ...
 })

Expects the following named parameters:

=over 4

=item * channel - which channel to perform the bind on

=back

Returns a L<Future> which resolves with ($queue) on
completion.

=cut

sub delete : method {
    my $self = shift;
    my %args = @_;
	my $ch = delete $args{channel} or die "No channel provided";

	retain_future($self->future->then(sub {
		my $f = $ch->loop->new_future->set_label("delete " . $self->queue_name);
		$ch->debug_printf("Deleting queue [%s]", $self->queue_name);

		my $frame = Net::AMQP::Frame::Method->new(
			method_frame => Net::AMQP::Protocol::Queue::Delete->new(
				queue       => Net::AMQP::Value::String->new($self->queue_name),
				nowait      => 0,
			)
		);
		$ch->push_pending(
			'Queue::DeleteOk' => [ $f, $self ],
		);
		$ch->closure_protection($f);
		$ch->send_frame($frame);
		$f
	}));
}

=head1 ACCESSORS

These are mostly intended for internal use only.

=cut

sub new {
	my ($class, %args) = @_;
	my $self = bless {}, $class;
	$self->configure(%args);
	$self
}

=head2 configure

Applies C<amqp> or C<future> value.

=cut

sub configure {
	my ($self, %args) = @_;
	for(grep exists $args{$_}, qw(amqp)) {
		Scalar::Util::weaken($self->{$_} = delete $args{$_})
	}
	for(grep exists $args{$_}, qw(future channel)) {
		$self->{$_} = delete $args{$_};
	}
	$self
}

=head2 amqp

A weakref to the L<Net::Async::AMQP> instance.

=cut

sub amqp { shift->{amqp} }

=head2 future

A ref to the L<Future> representing the queue readiness.

=cut

sub future { shift->{future} }

=head2 queue_name

Sets or returns the queue name.

=cut

sub queue_name {
    my $self = shift;
    return $self->{queue_name} unless @_;
    $self->{queue_name} = shift;
    $self
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
