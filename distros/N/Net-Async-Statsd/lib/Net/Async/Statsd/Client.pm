package Net::Async::Statsd::Client;
$Net::Async::Statsd::Client::VERSION = '0.005';
use strict;
use warnings;

use parent qw(IO::Async::Notifier);

=head1 NAME

Net::Async::Statsd::Client - asynchronous API for Etsy's statsd protocol

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 use Future;
 use IO::Async::Loop;
 use Net::Async::Statsd::Client;
 my $loop = IO::Async::Loop->new;
 $loop->add(my $statsd = Net::Async::Statsd::Client->new(
   host => 'localhost',
   port => 3001,
 ));
 # Wait until the stats are written before proceeding
 Future->needs_all(
  $statsd->timing(
   'some.task' => 133,
  ),
  $statsd->gauge(
   'some.value' => 80,
  )
 )->get;
 # Fire-and-forget stat, record 25% of the time:
 $statsd->increment('startup', 0.25);

=head1 DESCRIPTION

Provides an asynchronous API for statsd.

=head1 METHODS

All public methods return a L<Future> indicating when the write has completed.
Since writes are UDP packets, there is no guarantee that the remote will
receive the value, so this is mostly intended as a way to detect when
statsd writes are slow.

=cut

=head2 timing

Records timing information in milliseconds. Takes up to three parameters:

=over 4

=item * $k - the statsd key

=item * $v - the elapsed time in milliseconds

=item * $rate - optional sampling rate

=back

Only the integer part of the elapsed time will be sent.

Example usage:

 $statsd->timing('some.key' => $ms, 0.1); # record this 10% of the time

Returns a L<Future> which will be resolved when the write completes.

=cut

sub timing {
	my ($self, $k, $v, $rate) = @_;

	$self->queue_stat(
		$k => int($v) . '|ms',
		$rate
	);
}

=head2 gauge

Records a current value. Takes up to three parameters:

=over 4

=item * $k - the statsd key

=item * $v - the new value

=item * $rate - optional sampling rate

=back

Only the integer value will be sent.

Example usage:

 $statsd->timing('some.key' => 123);

Returns a L<Future> which will be resolved when the write completes.

=cut

sub gauge {
	my ($self, $k, $v, $rate) = @_;

	$self->queue_stat(
		$k => int($v) . '|g',
		$rate
	);
}

=head2 delta

Records changed value. Takes up to three parameters:

=over 4

=item * $k - the statsd key

=item * $v - the change (positive or negative)

=item * $rate - optional sampling rate

=back

Values are truncated to integers.

Example usage:

 $statsd->timing('some.key' => -12);

Returns a L<Future> which will be resolved when the write completes.

=cut

sub delta {
	my ($self, $k, $v, $rate) = @_;

	$self->queue_stat(
		$k => int($v) . '|c',
		$rate
	);
}

=head2 count

Alias for L</delta>.

=cut

# an alias for good measure
*count = *delta;

=head2 increment

Shortcut for L</delta> with a value of +1.

=cut

sub increment {
	my ($self, $k, $rate) = @_;

	$self->queue_stat(
		$k => '1|c',
		$rate
	);
}

=head2 decrement

Shortcut for L</delta> with a value of -1.

=cut

sub decrement {
	my ($self, $k, $rate) = @_;

	$self->queue_stat(
		$k => '-1|c',
		$rate
	);
}

=head2 configure

Standard L<IO::Async::Notifier> configuration - called on construction or
manually when values need updating.

Accepts the following named parameters:

=over 4

=item * host - the host we'll connect to

=item * port - the UDP port to send messages to

=item * default_rate - default sampling rate when none is provided for a given call

=item * prefix - string to prepend to any stats we record

=back

=cut

sub configure {
	my ($self, %args) = @_;
	for (qw(port host default_rate prefix)) {
		$self->{$_} = delete $args{$_} if exists $args{$_};
	}
	$self->SUPER::configure(%args);
}

=head1 INTERNAL METHODS

These methods are used internally, and are documented
for completeness. They may be of use when subclassing
this module.

=cut

=head2 queue_stat

Queues a statistic for write.

=cut

sub queue_stat {
	my ($self, $k, $v, $rate) = @_;

	$rate //= $self->default_rate;
	return Future->wrap unless $self->sample($rate);

	$k = $self->{prefix} . '.' . $k if exists $self->{prefix};

	# Append rate if we're only sampling part of the data
	$v .= '|@' . $rate if $rate < 1;
	my $f;
	$f = $self->statsd->then(sub {
		# FIXME Someday IO::Async::Socket may support
		# Futures for UDP send, update this if/when
		# that happens.
		shift->send("$k:$v");
		Future->wrap
	})->on_ready(sub { undef $f });
}

=head2 sample

Applies sampling based on the given rate - returns true if
we should record this, false otherwise.

=cut

sub sample {
	my ($self, $rate) = @_;
	return 1 if rand() <= $rate;
	return 0;
}

=head2 default_rate

Default sampling rate. Currently 1 if not overidden in constructor or L</configure>.

=cut

sub default_rate { shift->{default_rate} // 1 }

=head2 port

Statsd UDP port.

=cut

sub port { shift->{port} }

=head2 host

Statsd host to connect to.

=cut

sub host { shift->{host} }

sub statsd {
	my ($self) = @_;
	$self->{statsd} ||= do {
		$self->connect
	}
}

=head2 connect

Establishes the underlying UDP socket.

=cut

sub connect {
	my ($self) = @_;
	# IO::Async::Loop
	$self->loop->connect(
		family    => 'inet',
		socktype  => 'dgram',
		service   => $self->port,
		host      => $self->host,
		on_socket => $self->curry::on_socket,
	);
}

=head2 on_socket

Called when the socket is established.

=cut

sub on_socket {
	my ($self, $sock) = @_;
	$self->debug_printf("UDP socket established: %s", $sock->write_handle->sockhost_service);
	# FIXME Don't really want this - we're sending only, no bi-directional shenanigans
	# required, might need to replace ->connect with an IO::Async::Socket for this?
	$sock->configure(
		on_recv       => $self->curry::weak::on_recv,
		on_recv_error => $self->curry::weak::on_recv_error,
	);
	$self->add_child($sock);
}

=head2 on_recv

Called if we receive data.

=cut

sub on_recv {
	my ($self, undef, $dgram, $addr) = @_;
	$self->debug_printf("UDP packet [%s] received from %s", $dgram, join ':', $self->loop->resolver->getnameinfo(
		addr    => $addr,
		numeric => 1,
		dgram   => 1,
	));
}

=head2 on_recv_error

Called if we had an error while receiving.

=cut

sub on_recv_error {
	my ($self, undef, $err) = @_;
	$self->debug_printf("UDP packet receive error: %s", $err);
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<Net::Statsd> - synchronous implementation

=back

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2014-2016. Licensed under the same terms as Perl itself.
