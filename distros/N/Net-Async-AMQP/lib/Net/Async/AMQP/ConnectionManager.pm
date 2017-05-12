package Net::Async::AMQP::ConnectionManager;
$Net::Async::AMQP::ConnectionManager::VERSION = '2.000';
use strict;
use warnings;

use parent qw(IO::Async::Notifier);

=head1 NAME

Net::Async::AMQP::ConnectionManager - handle MQ connections

=head1 VERSION

version 2.000

=head1 SYNOPSIS

 use IO::Async::Loop;
 use Net::Async::AMQP;
 my $loop = IO::Async::Loop->new;
 $loop->add(
  my $cm = Net::Async::AMQP::ConnectionManager->new
 );
 $cm->add(
   host  => 'localhost',
   user  => 'guest',
   pass  => 'guest',
   vhost => 'vhost',
 );
 $cm->request_channel->then(sub {
   my $ch = shift;
   Future->needs_all(
     $ch->declare_exchange(
       'exchange_name'
     ),
     $ch->declare_queue(
       'queue_name'
     ),
   )->transform(done => sub { $ch })
 })->then(sub {
   my $ch = shift;
   $ch->bind_queue(
     'exchange_name',
	 'queue_name',
	 '*'
   )
 })->get;

=cut

use Future;
use Future::Utils qw(call try_repeat fmap_void);

use Time::HiRes ();
use Scalar::Util ();
use List::UtilsBy ();
use Variable::Disposition qw(retain_future);

use Net::Async::AMQP;
use Net::Async::AMQP::ConnectionManager::Channel;
use Net::Async::AMQP::ConnectionManager::Connection;

=head1 DESCRIPTION

=head2 Channel management

Each connection has N total available channels, recorded in a hash. The total number
of channels per connection is negotiated via the initial AMQP Tune/TuneOk sequence on
connection.

We also maintain lists:

=over 4

=item * Unassigned channel - these are channels which were in use and have now been released.

=item * Closed channel - any time a channel is closed, the ID is pushed onto this list so we can reopen it later without needing to scan the hash, contains arrayrefs of [$mq_conn, $id]

=back

Highest-assigned ID is also recorded per connection.

 if(have unassigned) {
 	return shift unassigned
 } elsif(have closed) {
 	my $closed = shift closed;
 	return $closed->{mq}->open_channel($closed->{id})
 } elsif(my $next_id = $mq->next_id) {
 	return $mq->open_channel($next_id)
 } else {
 
 }

Calling methods on the channel proxy will establish
a cycle for the duration of the pending request.
This cycle will not be resolved until after all
the callbacks have completed for a given request.

The channel object does not expose any methods that allow
altering QoS or other channel state settings. These must be
requested on channel assignment. This does not necessarily
mean that any QoS change will require allocation of a new
channel.

Bypassing the proxy object to change QoS flags is not recommended.

=head2 Connection pool

Connections are established on demand.

=head1 METHODS

=cut

sub configure {
	my ($self, %args) = @_;
	for(qw(channel_retry_count connect_timeout)) {
		$self->{$_} = delete $args{$_} if exists $args{$_};
	}
	$self->SUPER::configure(%args);
}

=head2 request_channel

Attempts to assign a channel with the given QoS settings.

Available QoS settings are:

=over 4

=item * prefetch_count - number of messages that can be delivered at a time

=item * prefetch_size - total size of messages allowed before acknowledging

=item * confirm_mode - explicit publish ack

=back

Confirm mode isn't really QoS but it fits in with the others since it modifies
the channel state (and once enabled, cannot be disabled without closing and
reopening the channel).

Will resolve to a L<Net::Async::AMQP::ConnectionManager::Channel> instance on success.

=cut

sub request_channel {
	my $self = shift;
	my %args = @_;

	die "We are shutting down" if $self->{shutdown_future};

	# Assign channel with matching QoS if available
	my $k = $self->key_for_args(\%args);
	if(exists $self->{channel_by_key}{$k} && @{$self->{channel_by_key}{$k}}) {
		my $ch = shift @{$self->{channel_by_key}{$k}};
		return $self->request_channel(%args) unless $ch->loop && !$ch->is_closed && !$ch->{closing};
		$self->debug_printf("Assigning %d from by_key cache", $ch->id);
		return Future->wrap(
			Net::Async::AMQP::ConnectionManager::Channel->new(
				channel => $ch,
				manager => $self,
			)
		)
	}

	# If we get here, we don't have an appropriate channel already available,
	# so whichever means we use to obtain a channel will need to set QoS afterwards
	my $f;

	if($self->can_reopen_channels && exists $self->{closed_channel} && @{$self->{closed_channel}}) {
		# If we have an ID for a closed channel then reuse that first.
		my ($mq, $id) = @{shift @{$self->{closed_channel}}};
		$self->debug_printf("Reopening closed channel %d", $id);
		$f = $mq->open_channel(
			channel => $id
		);
	} else {
		# Try to get a channel - limit this to 3 attempts
		my $count = 0;
		$f = try_repeat {
			$self->request_connection->then(sub {
				my $mq = shift;
				call {
					# If we have any spare IDs on this connection, attempt to open
					# a channel here
					if(my $id = $mq->next_channel) {
						return $mq->open_channel(
							channel => $id
						)
					}

					# No spare IDs, so record this to avoid hitting this MQ connection
					# on the next request as well
					$self->mark_connection_full($mq->amqp);

					# Just in case...
					delete $self->{pending_connection};

					# We can safely fail at this point, since we're in a loop and the
					# next iteration should get a new MQ connection to try with
					Future->fail(channel => 'no spare channels on connection');
				}
			});
		} until => sub {
			my $f = shift;
			return 1 if $f->is_done;
			return 0 unless defined(my $retry = $self->channel_retry_count);
			return 1 if ++$count > $retry
		}
	}

	# Apply our QoS on the channel if we ever get one
	return $f->then(sub {
		my $ch = shift;
		die "no channel provided?" unless $ch;
		call {
			$ch->bus->subscribe_to_event(
				close => $self->curry::weak::on_channel_close($ch),
			);
			$self->apply_qos($ch => %args)
		}
	})->set_label(
		'Channel QoS'
	)->transform(
		done => sub {
			my $ch = shift;
			$self->{channel_args}{$ch->id} = \%args;
			$self->debug_printf("Assigning newly-created channel %d", $ch->id);
			Net::Async::AMQP::ConnectionManager::Channel->new(
				channel => $ch,
				manager => $self,
			)
		}
	);
}

=head2 can_reopen_channels

A constant which indicates whether we can reopen channels. The AMQP0.9.1
spec doesn't seem to explicitly allow this, but it works with RabbitMQ 3.4.3
(and probably older versions) so it's enabled by default.

=cut

sub can_reopen_channels { 1 }

=head2 channel_retry_count

Returns the channel retry count. The default is 10, call L</configure>
with undef to retry indefinitely, 0 to avoid retrying at all:

 # Keep trying until it works
 $mq->configure(channel_retry_count => undef);
 # Don't retry at all
 $mq->configure(channel_retry_count => 0);

=cut

sub channel_retry_count {
	my $self = shift;
	# undef is a valid entry here
	if(!exists $self->{channel_retry_count}) {
		$self->{channel_retry_count} = 10;
	}
	$self->{channel_retry_count}
}

=head2 connect_timeout

Returns the current connection timeout. undef/zero means "no timeout".

=cut

sub connect_timeout { shift->{connect_timeout} }

=head2 apply_qos

Set QoS on the given channel.

Expects the L<Net::Async::AMQP::Channel> object as the first
parameter, followed by the key/value pairs corresponding to
the desired QoS settings:

=over 4

=item * prefetch_count - number of messages that can be delivered before ACK
is required

=back

Returns a L<Future> which will resolve to the original 
L<Net::Async::AMQP::Channel> instance.

=cut

sub apply_qos {
	my ($self, $ch, %args) = @_;
	(fmap_void {
		my $k = shift;
		my $v = $args{$k};
		my $method = "qos_$k";
		my $code = $self->can($method) or die "Unknown QoS setting $k (value $v)";
		$code->($self, $ch, $k => $v);
	} foreach => [
		sort keys %args
	])->transform(
		done => sub { $ch }
	)->set_label(
		'Apply QoS settings'
	);
}

sub qos_prefetch_size {
	my ($self, $ch, $k, $v) = @_;
	return $ch->qos(
		$k => $v
	)->set_label("Apply $k QoS");
}

sub qos_prefetch_count {
	my ($self, $ch, $k, $v) = @_;
	return $ch->qos(
		$k => $v
	)->set_label("Apply $k QoS");
}

sub qos_confirm_mode {
	my ($self, $ch) = @_;
	return $ch->confirm_mode(
	)->set_label("Apply confirm_mode QoS");
}

=head2 request_connection

Attempts to connect to one of the known AMQP servers.

=cut

sub request_connection {
	my ($self) = @_;
	die "We are shutting down" if $self->{shutdown_future};
	if(my $conn = $self->{pending_connection}) {
		$self->debug_printf("Requested connection and we have one pending, returning that");
		return $conn
	}

	if(exists $self->{available_connections} && @{$self->{available_connections}}) {
		$self->debug_printf("Assigning existing connection");
		return Future->wrap(
			Net::Async::AMQP::ConnectionManager::Connection->new(
				amqp    => $self->{available_connections}[0],
				manager => $self,
			)
		)
	}
	die "No connection details available" unless $self->{amqp_host};

	$self->debug_printf("New connection is required");
	my $timeout = $self->connect_timeout;
	retain_future(
		Future->wait_any(
			$self->{pending_connection} = $self->connect(
				%{$self->next_host}
			)->on_ready(sub {
				delete $self->{pending_connection};
			})->transform(
				done => sub {
					my $mq = shift;
					$mq->bus->subscribe_to_event(
						close => sub {
							# Drop this connection on close.
							my ($ev) = @_;
							eval { $ev->unsubscribe; };
							my $ref = Scalar::Util::refaddr($mq);
							List::UtilsBy::extract_by {
								Scalar::Util::refaddr($_) eq $ref
							} @{$self->{available_connections}};

							# Also remove from the full list...
							List::UtilsBy::extract_by {
								Scalar::Util::refaddr($_) eq $ref
							} @{$self->{full_connections}};

							# ... and any channels we had stashed
							List::UtilsBy::extract_by {
								Scalar::Util::refaddr($_->[0]) eq $ref
							} @{$self->{closed_channel}};

							# ... even the active ones
							for my $k (sort keys %{$self->{channel_by_key}}) {
								List::UtilsBy::extract_by {
									Scalar::Util::refaddr($_->amqp) eq $ref
								} @{$self->{channel_by_key}{$k}};
							}
						}
					);
					my $conn = Net::Async::AMQP::ConnectionManager::Connection->new(
						amqp    => $mq,
						manager => $self,
					);
					push @{$self->{available_connections}}, $mq;
					$conn
				}
			)->set_label(
				'Connect to MQ server'
			),
			( # Cancel the attempt if the timeout expires
				$timeout ?
				$self->loop->timeout_future(
					after => $self->connect_timeout,
				)->on_fail(sub {
					$self->{pending_connection}->cancel if $self->{pending_connection} && !$self->{pending_connection}->is_ready;
				})
				# ... if we had a timeout
				: ()
			)
		)->on_ready(sub {
			delete $self->{pending_connection}
		})
	)
}

=head2 next_host

Returns the next AMQP host.

=cut

sub next_host {
	my $self = shift;
	$self->{amqp_host}[rand @{$self->{amqp_host}}]
}

=head2 connect

Attempts a connection to an AMQP host.

=cut

sub connect {
	my ($self, %args) = @_;
	die "We are shutting down" if $self->{shutdown_future};
	$self->add_child(
		my $amqp = Net::Async::AMQP->new
	);
	$amqp->configure(heartbeat_interval => delete $args{heartbeat}) if exists $args{heartbeat};
	$amqp->configure(max_channels => delete $args{max_channels}) if exists $args{max_channels};
	$args{port} ||= 5672;
	$amqp->connect(
		%args
	)
}

=head2 mark_connection_full

Indicate that this connection has already allocated all available
channels.

=cut

sub mark_connection_full {
	my ($self, $mq) = @_;
	# Drop this from the available connection list
	push @{$self->{full_connections}}, $self->extract_conn(
		$mq,
		$self->{available_connections}
	);
	$self
}

sub extract_conn {
	my ($self, $conn, $stash) = @_;
	my @rslt = List::UtilsBy::extract_by {
		Scalar::Util::refaddr($_) == Scalar::Util::refaddr($conn)
	} @$stash;
	@rslt
}

=head2 key_for_args

Returns a key that represents the given arguments.

=cut

sub key_for_args {
	my ($self, $args) = @_;
	join ',', map { "$_=$args->{$_}" } sort keys %$args;
}

=head2 on_channel_close

Called when one of our channels has been closed.

=cut

sub on_channel_close {
	my ($self, $ch, $ev, %args) = @_;
	$self->debug_printf("channel closure: %s", join ' ', @_);
	# Channel closure only happens once per channel
	eval { $ev->unsubscribe; };

	$self->debug_printf("Adding closed channel %d back to the available list", $ch->id);
	my $amqp = $ch->amqp or die "This channel (" . $ch->id . ") has no AMQP connection";

	# We don't want to do anything with this channel if the parent connection is closed
	return unless $self->connection_valid($amqp);

	push @{$self->{closed_channel}}, [ $amqp, $ch->id ];

	# If this connection was in the full list, add it back to the available
	# list, since it now has spare channels
	push @{$self->{available_connections}}, $self->extract_conn(
		$amqp,
		$self->{full_connections}
	);
}

=head2 release_channel

Releases the given channel back to our channel pool.

=cut

sub release_channel {
	my ($self, $ch) = @_;
	return $self unless $ch && $ch->amqp && $self->connection_valid($ch->amqp);

	$self->debug_printf("Releasing channel %d", $ch->id);
	my $args = $self->{channel_args}{$ch->id};
	my $k = $self->key_for_args($args);
	push @{$self->{channel_by_key}{$k}}, $ch;
	$self
}

=head2 connection_valid

Returns true if this connection is one we know about, false if it's
closed or otherwise not usable.

=cut

sub connection_valid {
	my ($self, $amqp) = @_;
	my $ref = Scalar::Util::refaddr($amqp);
	return (
		grep {
			Scalar::Util::refaddr($_) eq $ref
		} @{$self->{available_connections}}, @{$self->{full_connections}}
	) ? 1 : 0;
}

=head2 add

Adds connection details for an AMQP server to the pool.

=cut

sub add {
	my ($self, %args) = @_;
	push @{$self->{amqp_host}}, \%args;
}

=head2 exch

=cut

sub exch {
	my ($self, $exch) = @_;
	return $self->{exchange}{$exch} if exists $self->{exchange}{$exch};
	$self->{exchange}{$exch} = $self->request_channel->then(sub {
		my $ch = shift;
		$ch->declare_exchange(
			$exch
		)
	});
}

sub queue {
	my ($self, $q) = @_;
	return $self->{queue}{$q} if exists $self->{queue}{$q};
	$self->{queue}{$q} = $self->request_channel->then(sub {
		my $ch = shift;
		$ch->declare_queue(
			$q
		)
	});
}

=head2 release_connection

Releases a connection.

Doesn't really do anything.

=cut

sub release_connection {
	my ($self, $mq) = @_;
	$self->debug_printf("Releasing connection %s", $mq);
}

sub connection_count {
	my ($self) = @_;
	@{$self->{available_connections}} + @{$self->{full_connections}}
}

sub _add_to_loop {
	my ($self, $loop) = @_;
	$self->{available_connections} ||= [];
	$self->{full_connections} ||= [];
}

sub shutdown {
	my $self = shift;
	$self->debug_printf("Shutdown started");
	die "Shutdown already in progress?" if $self->{shutdown_future};
	my $start = [Time::HiRes::gettimeofday];
	$self->{shutdown_future} = Future->wait_all(
		map $_->close, @{$self->{available_connections}}
	)->on_ready(sub {
		delete $self->{shutdown_future};
	})->on_done(sub {
		$self->debug_printf("All connections closed - elapsed %.3fs", Time::HiRes::tv_interval($start, [Time::HiRes::gettimeofday]));
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
