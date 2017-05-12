package Net::Async::Statsd::Server;
$Net::Async::Statsd::Server::VERSION = '0.005';
use strict;
use warnings;

use parent qw(IO::Async::Notifier);

=head1 NAME

Net::Async::Statsd::Server - asynchronous server for Etsy's statsd protocol

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 use Future;
 use IO::Async::Loop;
 use Net::Async::Statsd::Server;
 my $loop = IO::Async::Loop->new;
 $loop->add(my $statsd = Net::Async::Statsd::Server->new(
   port => 3001,
 ));
 $statsd->bus->subscribe_to_event(
  count => sub {
   my ($ev, $k, $delta, $type) = @_;
  }
 );

=head1 DESCRIPTION

Provides an asynchronous server for the statsd API.

=cut

use curry;
use Socket qw(SOCK_DGRAM);
use IO::Socket::IP;
use IO::Async::Socket;

use Net::Async::Statsd::Bus;

=head1 METHODS

All public methods return a L<Future> indicating when the write has completed.
Since writes are UDP packets, there is no guarantee that the remote will
receive the value, so this is mostly intended as a way to detect when
statsd writes are slow.

=cut

=head2 host

Which host to listen on. Probably want '0.0.0.0' (set via L</configure>)
here if you want to listen on all addresses.

=cut

sub host { shift->{host} }

=head2 port

The UDP port we'll accept traffic on. Use L</configure> to set it.

=cut

sub port { shift->{port} }

=head2 configure

Used for setting values.

=cut

sub configure {
	my ($self, %args) = @_;
	for (qw(port host)) {
		$self->{$_} = delete $args{$_} if exists $args{$_};
	}
	$self->SUPER::configure(%args);
}

=head2 listening

Resolves with the port number when the UDP server is listening.

=cut

sub listening {
	my ($self) = @_;
	$self->{listening} ||= do {
		$self->listen
	}
}

=head2 listen

Establishes the underlying UDP socket.

=cut

sub listen {
	my ($self) = @_;

	my $f = $self->loop->new_future;
	my $sock = IO::Socket::IP->new(
		Proto     => 'udp',
		ReuseAddr => 1,
		Type      => SOCK_DGRAM,
		LocalPort => $self->port // 0,
		Listen    => $self->listen_backlog,
		Blocking  => 0,
	) or die "No bind: $@\n";
	$self->{port} = $sock->sockport;
	my $ias = IO::Async::Socket->new(
		handle        => $sock,
		on_recv       => $self->curry::on_recv,
		on_recv_error => $self->curry::on_recv_error,
	);
	$self->add_child($ias);
	$f->done($self->port);
}

=head2 bus

Returns the L<Net::Async::Statsd::Bus> instance for this server.

This object exists purely for the purpose of dispatching events.

=cut

sub bus { shift->{bus} ||= Net::Async::Statsd::Bus->new }

=head2 listen_backlog

Default listen backlog. Immutable, set to 4096 for no particular reason.

=cut

sub listen_backlog { 4096 }

{
my %type = (
	ms => 'timing',
	c => 'count',
	g => 'gauge',
);

=head2 type_for_char

Badly-named lookup method - returns the type matching the given characters.

=cut

sub type_for_char {
	my ($self, $char) = @_;
	die "no character?" unless defined $char;
	return $type{$char};
}
}

=head2 on_recv

Called if we receive data.

=cut

sub on_recv {
	my ($self, undef, $dgram, $addr) = @_;
	$self->loop->resolver->getnameinfo(
		addr    => $addr,
		numeric => 1,
		dgram   => 1,
	)->on_done(sub {
		my ($host, $port) = @_;
		$self->debug_printf("UDP packet received from %s", join ':', $host, $port);
		my ($k, $v, $type_char, $rate) = $dgram =~ /^([^:]+):([^|]+)\|([^|]+)(?:\|\@(.+))?/ or warn "Invalid dgram: $dgram";
		$rate ||= 1;
		my $type = $self->type_for_char($type_char) // 'unknown';
		$self->bus->invoke_event(
			$type => ($k, $v, $rate, $host, $port)
		);
		$self->debug_printf(
			"dgram %s from %s: %s => %s (%s)",
			$dgram,
			join(':', $host, $port),
			$k,
			$v,
			$type
		);
	});
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
