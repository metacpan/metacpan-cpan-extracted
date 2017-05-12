package Net::Async::AMQP::ConnectionManager::Channel;
$Net::Async::AMQP::ConnectionManager::Channel::VERSION = '2.000';
use strict;
use warnings;

=head1 NAME

Net::Async::AMQP::ConnectionManager::Channel - channel proxy object

=head1 VERSION

version 2.000

=cut

use Time::HiRes ();

use Future::Utils qw(fmap_void);

use overload
    '""' => sub { shift->as_string },
    '0+' => sub { 0 + shift->id },
    bool => sub { 1 },
    fallback => 1;

=head1 METHODS

=head2 new

Instantiate. Expects at least the manager and channel named parameters.

=cut

sub new {
	my $class = shift;
	my $self = bless { @_ }, $class;
	Scalar::Util::weaken($_) for @{$self}{qw(manager channel)};

	# ->bus proxies to L<Net::Async::Channel/bus> via AUTOLOAD
	$self->bus->subscribe_to_event(
		my @ev = (
			listener_start => $self->curry::weak::_listener_start,
			listener_stop  => $self->curry::weak::_listener_stop,
		)
	);

	$self->{cleanup}{events} = sub {
		my $ch = shift;
		$ch->bus->unsubscribe_from_event(splice @ev);
		Future->done;
	};
	$self
}

=head2 _listener_start

Apply cleanup handler for a consumer: since we'll be releasing the
channel back into the general pool, any consumer that's still active
must be cancelled first.

=cut

sub _listener_start {
	my ($self, $ev, $ctag) = @_;

	my $k = "listener-$ctag";
	if(exists $self->{cleanup}{$k}) {
		# This is bad, since we should never have the same ctag twice
		die "Already had consumer tag $ctag";
	}

	$self->{cleanup}{$k} = sub {
		my $self = shift;
		Net::Async::AMQP::Queue->new(
			amqp    => $self->amqp,
			channel => $self,
			future  => Future->done()
		)->cancel(
			consumer_tag => $ctag
		)
	};
}

=head2 _listener_stop

Called when a listener has stopped. This will remove the associated cleanup task.

=cut

sub _listener_stop {
	my ($self, $ev, $ctag) = @_;
	delete $self->{cleanup}{"listener-$ctag"};
}

=head2 queue_declare

Override the usual queue declaration to ensure that we attach the wrapped channel
object (ourselves) rather than a raw L<Net::Async::AMQP::Channel> instance.

=cut

sub queue_declare {
	my ($self, %args) = @_;
	$self->channel->queue_declare(%args)->transform(
		done => sub {
			my ($q, @extra) = @_;
			# Ensure that this wrapped channel is used
			# as the stored channel value. This means
			# the channel holds the queue, we hold a weakref
			# to the channel, and the queue holds a strong
			# ref to our channel wrapper.
			$q->configure(channel => $self);
			return ($q, @extra);
		}
	)
}

=head2 confirm_mode

Don't allow this. If we want a confirm-mode-channel, it has to be assigned by passing
the appropriate request to the connection manager.

Without this we run the risk of burning through channels, for example:

=over 4

=item * Assign a channel with no options

=item * Enable confirm mode on that channel

=item * Release the channel

=item * Repeat

=back

This would eventually cause all available channels to end up in the "confirm mode"
available pool.

=cut

sub confirm_mode {
	my ($self) = @_;
	die "Cannot apply confirm mode to an existing channel";
}

sub last_call { shift->{last_call} }

=head2 channel

Returns the underlying AMQP channel.

=cut

sub channel { shift->{channel} }

=head2 manager

Returns our ConnectionManager instance.

=cut

sub manager { shift->{manager} }

=head2 as_string

String representation of the channel object.

Takes the form "ManagedChannel[N]", where N is the ID.

=cut

sub as_string {
	my $self = shift;
	sprintf "ManagedChannel[%d]", $self->id;
}

=head2 DESTROY

On destruction we release the channel by informing the connection manager
that we no longer require the data.

There may be some cleanup tasks required before we can release - cancelling
any trailing consumers, for example. These are held in the cleanup hash.

=cut

sub DESTROY {
	my $self = shift;
	return if ${^GLOBAL_PHASE} eq 'DESTRUCT';

	unless($self->{cleanup}) {
		my $conman = delete $self->{manager};
		my $ch = delete $self->{channel};
		return unless $conman; # global destruct
		return $conman->release_channel($ch);
	}

	return unless $self->{channel};

	my $f;
	my $cleanup = delete $self->{cleanup};
	$f = (
		fmap_void {
			my $k = shift;
			my $task = delete $cleanup->{$k};
			$task ? $task->($self) : Future->done
		} foreach => [
			sort keys %$cleanup
		]
	)->on_ready(sub {
		my $conman = delete $self->{manager};
		my $ch = delete $self->{channel};
		$conman->release_channel($ch) if $conman;
		undef $f;
	});
}

=head2 AUTOLOAD

All other methods are proxied to the underlying L<Net::Async::AMQP::Channel>.

=cut

sub AUTOLOAD {
	my ($self, @args) = @_;
	(my $method = our $AUTOLOAD) =~ s/.*:://;

	# We could check for existence first, but we wouldn't store the resulting coderef anyway,
	# so might as well just allow the method call to fail normally (we have no idea what
	# subclasses are used for $self->channel, using the first one we find would not be very nice)
	# die "attempt to proxy unknown method $method for $self" unless $self->channel->can($method);

	my $code = sub {
		my $self = shift;
		$self->{last_call} = Time::HiRes::time;
		$self->channel->$method(@_);
	};
	{ no strict 'refs'; *$method = $code }
	$code->(@_)
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
