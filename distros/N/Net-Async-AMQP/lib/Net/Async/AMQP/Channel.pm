package Net::Async::AMQP::Channel;
$Net::Async::AMQP::Channel::VERSION = '2.000';
use strict;
use warnings;

use parent qw(IO::Async::Notifier);

=head1 NAME

Net::Async::AMQP::Channel - represents a single channel in an MQ connection

=head1 VERSION

version 2.000

=head1 SYNOPSIS

 use IO::Async::Loop;
 use Net::Async::AMQP;
 my $loop = IO::Async::Loop->new;
 $loop->add(my $amqp = Net::Async::AMQP->new);
 $amqp->connect(
   host => 'localhost',
   username => 'guest',
   password => 'guest',
 )->then(sub {
  shift->open_channel->publish(
   type => 'application/json'
  )
 });

=head1 DESCRIPTION

Each Net::Async::AMQP::Channel instance represents a virtual channel for
communicating with the MQ server.

Channels are layered over the TCP protocol and most of the common AMQP frames
operate at channel level - typically you'd connect to the server, open one
channel for one-shot requests such as binding/declaring/publishing, and a further
channel for every consumer.

Since any error typically results in a closed channel, it's not recommended to
have multiple consumers on the same channel if there's any chance the Basic.Consume
request will fail.

=cut

use Future;
use curry::weak;
use Class::ISA ();
use Variable::Disposition qw(retain_future);
use Data::Dumper;
use Scalar::Util qw(weaken);

use Net::Async::AMQP;
use Net::Async::AMQP::Utils;

use overload
	'""' => sub { shift->as_string },
	'0+' => sub { 0 + shift->id },
	bool => sub { 1 },
	fallback => 1;

=head1 METHODS

=cut

sub configure {
	my ($self, %args) = @_;
	for(grep exists $args{$_}, qw(amqp)) {
		Scalar::Util::weaken($self->{$_} = delete $args{$_})
	}
	for(grep exists $args{$_}, qw(future id)) {
		$self->{$_} = delete $args{$_};
	}
	$self->SUPER::configure(%args);
}

=head2 confirm_mode

Switches confirmation mode on for this channel.
In confirm mode, all messages must be ACKed
explicitly after delivery.

Note that this is an irreversible operation - once
confirm mode has been enabled on a channel, closing that
channel and reopening is the only way to turn off confirm
mode again.

Returns a L<Future> which will resolve with this
channel once complete.

 $ch->confirm_mode ==> $ch

=cut

sub confirm_mode {
	my $self = shift;
	my %args = @_;
	$self->debug_printf("Enabling confirm mode");
	die "already requested confirm_mode for this channel" if $self->{confirm_mode};

	my $f = $self->loop->new_future->set_label("set confirm_mode on channel " . $self->id);
	$self->{delivery_tag} = 0;
	$self->{confirm_mode} = $f;
	my $nowait = $self->nowait_from_args(%args);
	my $frame = Net::AMQP::Frame::Method->new(
		method_frame => Net::AMQP::Protocol::Confirm::Select->new(
			nowait => $nowait,
		)
	);

	# No-wait mode means we don't expect the SelectOk frame back
	if($nowait) {
		$f->done
	} else {
		$self->closure_protection($f);
	}
	$self->send_frame($frame);
	return $f->transform(done => sub { $self });
}

=head2 nowait_from_args

If we have a C<wait> argument, then return the inverse of that.

Otherwise, return zero.

=cut

sub nowait_from_args {
	my ($self, %args) = @_;
	return 0 unless exists $args{wait};
	return $args{wait} ? 0 : 1;
}

=head2 exchange_declare

Declares a new exchange.

Returns a L<Future> which will resolve with this
channel once complete.

 $ch->exchange_declare(
  exchange   => 'some_exchange',
  type       => 'fanout',
  autodelete => 1,
 ) ==> $ch

=cut

sub exchange_declare {
	my $self = shift;
	my %args = @_;
	die "No exchange specified" unless exists $args{exchange};
	die "No exchange type specified" unless exists $args{type};

	$args{exchange} //= '';
	$self->debug_printf("Declaring exchange [%s]", $args{exchange});

	my $f = $self->loop->new_future->set_label("declare exchange [" . $args{exchange} . "]");
	my $frame = Net::AMQP::Frame::Method->new(
		method_frame => Net::AMQP::Protocol::Exchange::Declare->new(
			exchange    => Net::AMQP::Value::String->new($args{exchange}),
			type        => Net::AMQP::Value::String->new($args{type}),
			passive     => $args{passive} || 0,
			durable     => $args{durable} || 0,
			auto_delete => $args{auto_delete} || 0,
			internal    => $args{internal} || 0,
			ticket      => 0,
			nowait      => 0,
		)
	);
	$self->push_pending(
		'Exchange::DeclareOk' => [ $f, $self ]
	);
	$self->closure_protection($f);
	$self->send_frame($frame);
	return $f;
}

=head2 exchange_bind

Binds an exchange to another exchange. This is a RabbitMQ-specific extension.

=cut

sub exchange_bind {
    my $self = shift;
    my %args = @_;
    die "No source exchange specified" unless exists $args{source};
    die "No destination exchange specified" unless exists $args{destination};

	$self->debug_printf("Binding exchange [%s] to [%s] with rkey [%s]", $args{source}, $args{destination}, $args{routing_key});

	my $f = $self->loop->new_future->set_label("bind exchange [" . $args{source} . "] to [" . $args{destination} . "]" . (exists $args{routing_key} ? (" rkey [" . $args{routing_key} . "]") : ""));
	my $frame = Net::AMQP::Frame::Method->new(
		method_frame => Net::AMQP::Protocol::Exchange::Bind->new(
			source      => Net::AMQP::Value::String->new($args{source}),
			destination => Net::AMQP::Value::String->new($args{destination}),
			(exists($args{routing_key}) ? ('routing_key' => Net::AMQP::Value::String->new($args{routing_key})) : ()),
			nowait      => 0,
		)
	);
	$self->push_pending(
		'Exchange::BindOk' => [ $f, $self ]
	);
	$self->closure_protection($f);
	$self->send_frame($frame);
	return $f;
}

=head2 queue_declare

Returns a L<Future> which will resolve with the new L<Net::Async::AMQP::Queue> instance,
the number of messages in the queue, and the number of consumers.

 $ch->queue_declare(
  queue      => 'some_queue',
 ) ==> ($q, $message_count, $consumer_count)

=cut

sub queue_declare {
	my $self = shift;
	my %args = @_;
	die "No queue specified" unless defined $args{queue};

	$self->future->then(sub {
		my $f = $self->loop->new_future->set_label("declare queue [" . $args{queue} . "]");
		my $ready = $self->loop->new_future->set_label("queue readiness for [" . $args{queue} . "]");
		my $q = Net::Async::AMQP::Queue->new(
			amqp    => $self->amqp,
			future  => $ready,
		);
		$self->debug_printf("Declaring queue [%s]", $args{queue});
		my $frame = Net::AMQP::Frame::Method->new(
			method_frame => Net::AMQP::Protocol::Queue::Declare->new(
				queue       => Net::AMQP::Value::String->new($args{queue}),
				passive     => $args{passive} || 0,
				durable     => $args{durable} || 0,
				exclusive   => $args{exclusive} || 0,
				auto_delete => $args{auto_delete} || 0,
				no_ack      => $args{no_ack} || 0,
				($args{arguments}
				? (arguments   => $args{arguments})
				: ()
				),
				ticket      => 0,
				nowait      => 0,
			)
		);
		$self->push_pending(
			'Queue::DeclareOk' => sub {
				my ($amqp, $frame) = @_;
				my $method_frame = $frame->method_frame;
				$q->queue_name($method_frame->queue);
				my $messages = $method_frame->message_count;
				my $consumer_count = $method_frame->consumer_count;
				$ready->done() unless $ready->is_ready;
				$f->done($q, $messages, $consumer_count) unless $f->is_ready;
			}
		);
		$self->closure_protection($f);
		$self->send_frame($frame);
		$f;
	})
}

sub next_dtag { ++shift->{delivery_tag} }

=head2 publish

Publishes a message on this channel.

Returns a L<Future> which will resolve with the
channel instance once the server has confirmed publishing is complete.

 $ch->publish(
  exchange => 'some_exchange',
  routing_key => 'some.rkey.here',
  type => 'some_type',
 ) ==> $ch

Some named parameters currently accepted - note that this list is likely to
expand in future:

=over 4

=item * ack - we default to ACK mode, so set this to 0 to turn off explicit server ACK
on message routing/delivery

=item * immediate - if set, will cause a failure if the message could not be routed
immediately to a consumer

=item * mandatory - if set, will require that the message ends up in a queue (i.e. will
fail messages sent to an exchange that do not have an appropriate binding)

=item * content_type - defaults to application/binary

=item * content_encoding - defaults to undef (none)

=item * timestamp - the message timestamp, defaults to epoch time

=item * expiration - use this to set per-message expiry, see L<https://www.rabbitmq.com/ttl.html>

=item * priority - defaults to undef (none), use this to take advantage of RabbitMQ 3.5+ priority support

=item * reply_to - which queue to reply to (used for RPC, default undef)

=item * correlation_id - unique message ID (used for RPC, default undef)

=item * delivery_mode - whether to persist message (default 1, don't persist - set to 2 for persistent, see also "durable" flag for queues)

=back

=cut

sub publish {
	my $self = shift;
	my %args = @_;
	die "no exchange" unless exists $args{exchange};

	$self->future->then(sub {
		my $f = $self->loop->new_future->set_label("publish on [" . $args{exchange} . "]");
		my $dtag = $self->next_dtag;
		if($self->{confirm_mode}) {
			push @{$self->{published}}, [ $dtag => $f ];
		} else {
			$f->done;
		}

		my @frames = $self->amqp->split_payload(
			$args{payload},
			exchange         => Net::AMQP::Value::String->new($args{exchange}),
			mandatory		 => $args{mandatory} // 0,
			immediate        => $args{immediate} // 0,
			(exists $args{routing_key} ? (routing_key => Net::AMQP::Value::String->new($args{routing_key})) : ()),
			ticket           => 0,
			content_type     => $args{content_type} // 'application/binary',
			content_encoding => $args{content_encoding},
			timestamp        => $args{timestamp} // time,
			type             => Net::AMQP::Value::String->new($args{type} // ''),
			user_id          => $self->amqp->user,
            headers          => $args{headers} || { },
			delivery_mode    => $args{delivery_mode} // 1,
			priority         => $args{priority} // 1,
			correlation_id   => $args{correlation_id},
			expiration       => (
				exists $args{expiration}
				# This would seem to make more sense as a numeric value, but the spec
				# defines this as a shortstr
				? Net::AMQP::Value::String->new($args{expiration})
				: undef
			),
			message_id       => $args{message_id},
			app_id           => $args{app_id},
			cluster_id       => $args{cluster_id},
			reply_to         => $args{reply_to},
			weight           => $args{weight} // 0,
		);
		$self->closure_protection($f);
		$self->send_frame(
			$_,
		) for @frames;
		$f
	})
}

=head2 qos

Changes QOS settings on the channel. Probably most
useful for limiting the number of messages that can
be delivered to us before we have to ACK/NAK to
proceed.

Returns a L<Future> which will resolve with the
channel instance once the operation is complete.

 $ch->qos(
  prefetch_count => 5,
  prefetch_size  => 1048576,
 ) ==> $ch

=cut

sub qos {
	my $self = shift;
	my %args = @_;

	$self->future->then(sub {
		my $f = $self->loop->new_future->set_label("set qos count " . ($args{prefetch_count} // 0) . " size " . ($args{prefetch_size} // 0));
		my $channel = $self->id;
		$self->push_pending(
			'Basic::QosOk' => [ $f, $self ],
		);

		my $frame = Net::AMQP::Frame::Method->new(
			method_frame => Net::AMQP::Protocol::Basic::Qos->new(
				nowait         => 0,
				prefetch_count => $args{prefetch_count},
				prefetch_size  => $args{prefetch_size} || 0,
			)
		);
		$self->closure_protection($f);
		$self->send_frame($frame);
		$f
	});
}

=head2 ack

Acknowledge a specific delivery.

Returns a L<Future> which will resolve with the
channel instance once the operation is complete.

 $ch->ack(
  delivery_tag => 123,
 ) ==> $ch

=cut

sub ack {
	my $self = shift;
	my %args = @_;

	my $id = $self->id;
	$self->future->on_done(sub {
		my $channel = $id;
		my $frame = Net::AMQP::Frame::Method->new(
			method_frame => Net::AMQP::Protocol::Basic::Ack->new(
			   # nowait      => 0,
				delivery_tag => $args{delivery_tag},
				multiple     => $args{multiple} // 0,
			)
		);
		$self->send_frame($frame);
	});
}

=head2 nack

Negative acknowledgement for a specific delivery.

Returns a L<Future> which will resolve with the
channel instance once the operation is complete.

 $ch->nack(
  delivery_tag => 123,
 ) ==> $ch

=cut

sub nack {
	my $self = shift;
	my %args = @_;

	my $id = $self->id;
	$self->future->on_done(sub {
		my $channel = $id;
		my $frame = Net::AMQP::Frame::Method->new(
			method_frame => Net::AMQP::Protocol::Basic::Nack->new(
			   # nowait      => 0,
				delivery_tag => $args{delivery_tag},
				multiple     => $args{multiple} // 0,
				requeue      => $args{requeue} // 0,
			)
		);
		$self->send_frame($frame);
	});
}

=head2 reject

Reject a specific delivery.

Returns a L<Future> which will resolve with the
channel instance once the operation is complete.

 $ch->nack(
  delivery_tag => 123,
 ) ==> $ch

=cut

sub reject {
	my ($self, %args) = @_;

	my $id = $self->id;
	$self->future->on_done(sub {
		my $channel = $id;
		my $frame = Net::AMQP::Frame::Method->new(
			method_frame => Net::AMQP::Protocol::Basic::Reject->new(
			   # nowait      => 0,
				delivery_tag => $args{delivery_tag},
				multiple     => $args{multiple} // 0,
				requeue      => $args{requeue} // 0,
			)
		);
		$self->send_frame($frame);
	});
}

=pod

Example output:

		'method_id' => 40,
		'reply_code' => 404,
		'class_id' => 60,
		'reply_text' => 'NOT_FOUND - no exchange \'invalidchan\' in vhost \'vhost\''

=cut

=head2 on_close

Called when the channel has been closed.

=cut

sub on_close {
	my ($self, $frame) = @_;

	$self->{is_closed} = 1;
	$self->{future} = Future->fail('closed');

	# ACK the close first - we have to send a close-ok
	# before it's legal to reopen this channel ID
	retain_future(
		(
			  # If we initiated the close, then the CloseOk comes from the server
			  $self->{closing}
			? Future->done
			: $self->send_frame(
				Net::AMQP::Frame::Method->new(
					method_frame => Net::AMQP::Protocol::Channel::CloseOk->new(
					)
				)
			)
		)->on_ready(sub {
			# Any remaining consumers need to be cancelled at this point
			$self->bus->invoke_event(
				'cancel',
				ctag => $_,
			) for keys %{$self->{consumer_tags}};
			$self->{consumer_tags} = {};

			$_->fail('channel closed') for grep !$_->is_ready, map $_->[1], @{$self->{published}};
			$self->{published} = [];

			# It's important that the MQ instance knows
			# about the channel closure first before we
			# go ahead and dispatch events, since any
			# subscribed handlers might go ahead and
			# attempt to open the channel again immediately.

			$self->amqp->channel_closed($self->id);
			$self->bus->invoke_event(
				'close',
				code => $frame->reply_code,
				reason => $frame->reply_text,
			);
			Future->done
		})
	)
}

=head2 send_frame

Proxy frame sending requests to the parent
L<Net::Async::AMQP> instance.

=cut

sub send_frame {
	my $self = shift;
	$self->amqp->send_frame(
		@_,
		channel => $self->id,
	)
}

=head2 close

Ask the server to close this channel.

Returns a L<Future> which will resolve with the
channel instance once the operation is complete.

 $ch->close(
  code => 404,
  text => 'something went wrong',
 ) ==> $ch

=cut

sub close {
	my $self = shift;
	my %args = @_;
	$self->debug_printf("Close channel %d", $self->id);

	# There's a slight chance we'll get called after being
	# removed from the loop, since we wanted to close anyway then
	# don't treat that as an error
	return Future->done if $self->{closing} or !$self->loop;

	$self->{closing} = 1;
	$self->{future} = Future->fail('closing');

	my $f = $self->loop->new_future->set_label("Close channel " . $self->id);
	my $frame = Net::AMQP::Frame::Method->new(
		method_frame => Net::AMQP::Protocol::Channel::Close->new(
			reply_code  => $args{code} // 404,
			reply_text  => $args{text} // 'closing',
		)
	);
	$self->push_pending(
		'Channel::CloseOk' => [ $f, $self ],
	);
	$self->closure_protection($f);
	$self->send_frame($frame);
	return $f;
}

=head2 push_pending

=cut

sub push_pending {
	my $self = shift;
	while(@_) {
		my ($type, $code) = splice @_, 0, 2;
		push @{$self->{pending}{$type}}, $code;
	}
	return $self;
}

=head2 remove_pending

Removes a coderef from the pending event handler.

Returns C< $self >.

=cut

sub remove_pending {
	my $self = shift;
	while(@_) {
		my ($type, $code) = splice @_, 0, 2;
		# This is the same as extract_by { $_ eq $code } @{$self->{pending}{$type}};,
		# but since we'll be calling it a lot might as well do it inline:
		splice
			@{$self->{pending}{$type}},
			$_,
			1 for grep {
				$self->{pending}{$type}[$_] eq $code
			} reverse 0..$#{$self->{pending}{$type}};
	}
	return $self;
}

=head2 next_pending

Retrieves the next pending handler for the given incoming frame type (see L<Net::Async::AMQP::Utils/amqp_frame_type>),
and calls it.

Takes the following parameters:

=over 4

=item * $frame - the frame itself

=back

Returns $self.

=cut

sub next_pending {
	my ($self, $frame) = @_;

	# First part of a frame. There's more to come, so stash a new future
	# and return.
	if($frame->isa('Net::AMQP::Frame::Header')) {
		# Properties are available directly from the header frame
		my $hdr_frame = $frame->header_frame;
		$self->{incoming_message}{type} = $hdr_frame->type;
		$self->{incoming_message}{properties} = {
			map {; $_ => scalar($hdr_frame->$_) } qw(
				content_type 
				content_encoding
				delivery_mode
				priority
				correlation_id
				reply_to
				expiration
				message_id
				timestamp
				user_id
				app_id
			)
		};
		if($frame->header_frame->headers) {
			eval {
				#$self->{incoming_message}{type} = $frame->header_frame->headers->{type}
				#	if exists $frame->header_frame->headers->{type};
				# Shallow copy for local storage
				$self->{incoming_message}{headers} = { %{$frame->header_frame->headers} };
				1
			} or $self->debug_printf("Unexpected exception while doing something: %s", $@);
		} else {
			$self->{incoming_message}{headers} = {};
		}

		if($frame->body_size) {
			# Stash the size so we can do some basic validation on the payload frames
			$self->{incoming_message}{pending} = $frame->body_size;
		} else {
			# Messages may be empty - in this case we'd have no body frames at all, we're done already:
			$self->deliver_current_message;
		}

		return $self;
	}

	# Body part of an incoming message.
	if($frame->isa('Net::AMQP::Frame::Body')) {
		my $bytes = $frame->payload;
		$self->{incoming_message}{payload} .= $bytes;
		$self->{incoming_message}{pending} -= length $bytes;
		if($self->{incoming_message}{pending} > 0) {
			# We still have more to come, just return for now
			return $self;
		} elsif($self->{incoming_message}{pending} < 0) {
			$self->close(
				code => 500,
				text => -$self->{incoming_message}{pending} . ' excess payload bytes detected in delivery'
			);
			delete $self->{incoming_message};
			return $self;
		} else {
			# We have a full message now - hand it over to the event bus
			$self->deliver_current_message;
			return $self;
		}
	}

	return $self unless $frame->can('method_frame') && (my $method_frame = $frame->method_frame);
	my $type = amqp_frame_type($frame);
	if($type eq 'Basic::ConsumeOk') {
		my $ctag = $method_frame->consumer_tag;
		$self->{consumer_tags}{$ctag} = 1;
	} elsif($type eq 'Basic::Cancel' or $type eq 'Basic::CancelOk') {
		my ($ctag) = ($method_frame->consumer_tag);
		$self->debug_printf("Cancel $ctag");
		$self->bus->invoke_event(
			'cancel',
			ctag => $ctag,
		);
		# Also raise this as a "listener_stop"
		# event, for managed channels
		$self->bus->invoke_event(
			listener_stop => $ctag
		);
		delete $self->{consumer_tags}{$ctag};
	}

	# Message delivery, part 3: The "Deliver" message.
	# This is actually where we start.
	if($type eq 'Basic::Deliver') {
		$self->debug_printf("Already have incoming_message?") if exists $self->{incoming_message};
		$self->{incoming_message} = {
			ctag => $method_frame->consumer_tag,
			dtag => $method_frame->delivery_tag,
			rkey => $method_frame->routing_key,
			payload => '',
			payload_size => undef,
		};
		return $self;
	}

	if($type eq 'Channel::Close') {
		$self->debug_printf(
			"Channel was %d, calling close - code %d, text '%s', class:method %d:%d",
			$frame->channel,
			$method_frame->reply_code,
			$method_frame->reply_text,
			$method_frame->class_id,
			$method_frame->method_id,
		);
		$self->on_close(
			$method_frame
		);
		return $self;
	}

	# Confirm mode => mark pending task as done
	if($type eq 'Confirm::SelectOk') {
		$self->debug_printf("Confirm mode enabled");
		$self->{confirm_mode}->done;
		return $self;
	} elsif($type eq 'Basic::Ack') {
		shift @{$self->{pending}{'Basic::Return'} || []};
		eval {
			my @msg = $self->extract_published($method_frame->delivery_tag, $method_frame->multiple);
			$self->debug_printf("received ack for %d messages", 0 + @msg);
			$_->done for grep !$_->is_ready, map $_->[1], @msg;
			1
		} or do {
			my $err = $@;
			$self->debug_printf("error retrieving messages for ack - %s", $err);
			$self->close(
				code => 406,
				text => $err
			);
		};
		return $self;
	} elsif($type eq 'Basic::Nack') {
		shift @{$self->{pending}{'Basic::Return'} || []};
		eval {
			my @msg = $self->extract_published($method_frame->delivery_tag, $method_frame->multiple);
			$self->debug_printf("received nack for %d messages", 0 + @msg);
			$_->fail('nack') for grep !$_->is_ready, map $_->[1], @msg;
			1
		} or do {
			my $err = $@;
			$self->debug_printf("error retrieving messages for nack - %s", $err);
			$self->close(
				code => 406,
				text => $err
			);
		};
		return $self;
	} elsif($type eq 'Basic::Return') {
		# Basic::Return would always be for the first unacked message in our publish
		# queue... except when we don't have publisher confirms, in which case... uh...
		# okay in that case we'd just raise an event maybe
		if($self->{confirm_mode}) {
			$self->debug_printf("basic::return in confirm mode");
			my $f = $self->{published}[0][1];
			$f->fail(
				$method_frame->reply_text,
				code     => $method_frame->reply_code,
				exchange => $method_frame->exchange,
				rkey     => $method_frame->routing_key
			) if $f && !$f->is_ready;
		} else {
			$self->debug_printf("basic::return in normal mode");
			$self->bus->invoke_event(
				return => $method_frame->reply_text,
				code     => $method_frame->reply_code,
				exchange => $method_frame->exchange,
				rkey     => $method_frame->routing_key
			)
		}
		return $self;
	}

	if(my $next = shift @{$self->{pending}{$type} || []}) {
		# We have a registered handler for this frame type. This usually
		# means that we've sent a message and are awaiting a response.
		if(ref($next) eq 'ARRAY') {
			my ($f, @args) = @$next;
			$f->done(@args) unless $f->is_ready;
		} else {
			$next->($self, $frame, @_);
		}
		return $self;
	}

	# It's quite possible we'll see unsolicited frames back from
	# the server. We don't expect many so report them when in debug mode.
	$self->debug_printf("We had no pending handlers for [%s]", $type);
	return $self;
}

sub deliver_current_message {
	my $self = shift;
	$self->bus->invoke_event(
		message => @{$self->{incoming_message}}{qw(type payload ctag dtag rkey headers properties)},
	);
	delete $self->{incoming_message};
}

sub extract_published {
	my ($self, $dtag, $multiple) = @_;
	if($multiple) {
		my @msg;
		while(@{$self->{published}}) {
			my $msg = shift @{$self->{published}};
			# Nonzero dtag means "up to and including this message"
			die 'ack for dtag ' . $dtag . ' but our earliest message is ' . $msg->[0] if $dtag && $dtag < $msg->[0];

			# with dtag=0 that's "everything you've got". this is fundamentally
			# flawed since the server may not have even received the most recent
			# items... might work if the server *always* uses dtag=0, I guess
			push @msg, $msg;
			last if $dtag == $msg->[0];
		}
		return @msg;
	}
	# Single-ack *probably* handles things in order, but the spec does not seem
	# to mandate this - better to be safe
	for my $idx (0..$#{$self->{published}}) {
		return splice @{$self->{published}}, $idx, 1 if $self->{published}[$idx][0] == $dtag;
	}
	die 'ack for dtag ' . $dtag . ' but not found in our pending list (we had ' . @{$self->{published}} . ' pending messages)';
}

=head1 METHODS - Accessors

=cut

=head2 amqp

The parent L<Net::Async::AMQP> instance.

=cut

sub amqp { shift->{amqp} }

=head2 bus

Event bus. Used for sharing channel-specific events.

=cut

sub bus { $_[0]->{bus} ||= Mixin::Event::Dispatch::Bus->new }

=head2 future

The underlying L<Future> for this channel.

Will resolve to the L<Net::Async::Channel> instance once the channel is open.

=cut

sub future { shift->{future} }

=head2 id

This channel ID.

=cut

sub id {
	my $self = shift;
	return $self->{id} unless @_;
	$self->{id} = shift;
	$self
}

sub as_string {
	my $self = shift;
	sprintf "Channel[%d]", $self->id;
}

=head2 closed

Returns true if the channel has been closed, 1 if not (which could mean it is either not yet open,
or that it is open and has not yet been closed by either side).

=cut

sub is_closed { shift->{is_closed} }

=head2 closure_protection

Helper method for marking any outstanding requests as failed when the channel closes.

Takes a L<Future>, returns a L<Future> (probably the same one).

=cut

sub closure_protection {
	my ($self, $f) = @_;
	unless($f) {
		$self->debug_printf("Closure protection requested on channel %d for future which has already disappeared", $self->id);
		return Future->fail(closed => 'future has already been released');
	}

	# No sense in proceeding if the Future has already completed
	if($f->is_ready) {
		$self->debug_printf("Closure protection requested for future %s on channel %d which has already compelted", $f->label, $self->id);
		return $f;
	}

	my $id = $self->id;
	my @ev;
	my $bus = $self->bus;
	$bus->subscribe_to_event(
		@ev = (close => sub {
			my ($ev, %args) = @_;
			$self->debug_printf("Closure protection engaging for %s on channel %d, code %s, reason: %s", ($f ? $f->label : "(future which no longer exists)"), $id, $args{code} // '(none)', $args{reason});
			if($f) {
				$f->fail($args{reason}, 'amqp', $args{code}) unless $f->is_ready;
			} else {
				$self->debug_printf("Future has disappeared already, not marking as failed");
			}
			# We should have unsubscribed already, but do this just in case.
			splice @ev;
			eval { $ev->unsubscribe; };
		})
	);

	# Use return value from ->on_ready, since we may clear $f immediately if the future is already
	# marked as ready.
	$f->on_ready(sub {
		$self->debug_printf("Future %s on channel %d is ready, disengaging closure protection", ($f ? $f->label : "(future which no longer exists)"), $id);
		eval { $bus->unsubscribe_from_event(splice @ev); };
		undef $f;
	});
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
