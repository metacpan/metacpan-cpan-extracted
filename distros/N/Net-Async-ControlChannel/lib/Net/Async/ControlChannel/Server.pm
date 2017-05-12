package Net::Async::ControlChannel::Server;
$Net::Async::ControlChannel::Server::VERSION = '0.005';
use strict;
use warnings;
use parent qw(Mixin::Event::Dispatch);

=encoding utf8

=head1 NAME

Net::Async::ControlChannel::Server - server implementation for L<Protocol::ControlChannel> using L<IO::Async>

=head1 VERSION

Version 0.005

=head1 SYNOPSIS

 use Net::Async::ControlChannel::Server;
 use IO::Async::Loop;
 my $loop = IO::Async::Loop->new;
 my $server = Net::Async::ControlChannel::Server->new(
  loop => $loop,
 );
 $server->subscribe_to_event(
  message => sub {
   my $ev = shift;
   my ($k, $v, $from) = @_;
   warn "Server: Had $k => $v from $from\n";
  }
 );
 $server->start;
 $loop->run;

=head1 DESCRIPTION

Provides the server half for a control channel connection.

=cut

use Protocol::ControlChannel;
use Future;
use curry;
use curry::weak;
use List::UtilsBy qw(sort_by);

=head1 METHODS

=cut

use Scalar::Util qw(weaken refaddr);

=head2 new

Instantiates the server object. Will not establish the listener,
but does expect to receive an L<IO::Async::Loop> as the C<loop> named
parameter.

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless {
		loop => (delete($args{loop}) or die 'no loop?'),
		%args,
	}, $class;
	weaken($self->{loop});
	$self->{protocol} = Protocol::ControlChannel->new;
	$self;
}

=head1 ACCESSOR METHODS

=head2 loop

The L<IO::Async::Loop> instance we're (going to be) attached to.

=cut

sub loop { shift->{loop} }

=head2 host

Our host. Will be populated after L</start> has been called.

=cut

sub host { shift->{host} }

=head2 port

Our listening port. Will be populated after L</start> has been called.

=cut

sub port { shift->{port} }

=head2 proto

The L<Protocol::ControlChannel> instance. Mainly for internal use.

=cut

sub proto { shift->{protocol} }

=head2 clients

All currently-connected clients, as a list.

=cut

sub clients { sort_by { $_->{remote} } values %{ shift->{clients} } }

=head2 dispatch

Sends a message to all clients.

Expects two parameters:

=over 4

=item * $k - the key we're sending

=item * $v - the content (can be a ref, in which case it will be encoded
using whichever mechanism has been negotiated with the client)

=back

Returns a L<Future> which will resolve when we think we've delivered
to all connected clients.

=cut

sub dispatch {
	my $self = shift;
	return Future->new->done unless my @clients = $self->clients;

	my $void = !defined wantarray;
	my @pending;
	# Current implementation sends the same frame to all clients, so populate it once
	# TODO once encoding negotiation is implemented this will need to be per-client
	my $frame = $self->proto->create_frame(@_);
	for my $client (map $_->{stream}, $self->clients) {
		my @args;

		# No need to instantiate futures unless we're going to use the result somewhere
		unless($void) {
			my $f = Future->new;
			push @args, on_flush => sub { $f->done };
			push @pending, $f;
		}
		$client->write($frame, @args);
	}
	return if $void;

	Future->needs_all(@pending);
}

=head2 start

Start the listener. Will return a L<Future> which resolves with our
instance once the listening socket is active.

=cut

sub start {
	my $self = shift;
	$self->loop->listen(
		addr => {
			family   => 'inet',
			socktype => 'stream',
			ip       => $self->host || '0.0.0.0',
			port     => $self->port || 0,
		},
		on_listen => $self->curry::listen_active,
		on_listen_error => $self->curry::listen_error,
		on_stream => $self->curry::incoming_stream,
	);
	$self->listening;
}

=head2 listening

The L<Future> corresponding to the listening connection. Resolves with our
instance.

=cut

sub listening { shift->{listening} ||= Future->new }

=head2 listen_active

Called internally when the listen action is complete.

=cut

sub listen_active {
	my $self = shift;
	my $sock = shift;
	$self->{host} = $sock->sockhost;
	$self->{port} = $sock->sockport;
	$self->listening->done($self);
}

=head2 listen_error

Called when there's an error. Marks L</listening> as failed.

=cut

sub listen_error {
	my $self = shift;
	$self->listening->fail(@_);
}

=head2 incoming_stream

Called internally for each incoming client.

=cut

sub incoming_stream {
	my $self = shift;
	my $stream = shift;
	my $remote = join ':', map $stream->read_handle->$_, qw(peerhost peerport);
	$self->{clients}{refaddr $stream} = {
		remote => $remote,
		stream => $stream,
	};
	$stream->configure(
		on_read => $self->curry::weak::incoming_message($remote),
	);
	$self->loop->add($stream);
	$self->invoke_event(connect => $remote);
}

=head2 incoming_message

Called internally when we have data from a client.

=cut

sub incoming_message {
	my ($self, $remote, $stream, $buffer, $eof) = @_;
	die "Message received from unknown client" unless exists $self->{clients}{refaddr $stream};
	while(my $frame = $self->proto->extract_frame($buffer)) {
		$self->invoke_event(message => $frame->{key}, $frame->{value}, $remote);
	}
	if($eof) {
		$self->invoke_event(disconnect => $remote);
		delete $self->{clients}{refaddr $stream};
	}
	return 0;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2012-2013. Licensed under the same terms as Perl itself.
