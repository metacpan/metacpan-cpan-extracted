package Net::Async::UWSGI::Server;
$Net::Async::UWSGI::Server::VERSION = '0.006';
use strict;
use warnings;

use parent qw(IO::Async::Notifier);

=head1 NAME

Net::Async::UWSGI::Server - server implementation for UWSGI

=head1 VERSION

version 0.006

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use curry;
use curry::weak;

use IO::Async::Listener;

use Mixin::Event::Dispatch::Bus;
use Net::Async::UWSGI::Server::Connection;

use Scalar::Util qw(weaken);
use URI;
use URI::QueryParam;
use JSON::MaybeXS;
use Encode qw(encode);
use Future;
use HTTP::Response;

use Protocol::UWSGI qw(:server);

=head1 METHODS

=cut

=head2 path

=cut

sub path { shift->{path} }

=head2 backlog

=cut

sub backlog { shift->{backlog} }

=head2 mode

=cut

sub mode { shift->{mode} }

=head2 configure

=cut

sub configure {
	my ($self, %args) = @_;
	for(qw(path backlog mode on_request)) {
		$self->{$_} = delete $args{$_} if exists $args{$_};
	}
	$self->SUPER::configure(%args);
}

=head2 _add_to_loop

=cut

sub _add_to_loop {
	my ($self, $loop) = @_;
	delete $self->{listening};
	$self->listening;
	()
}

=head2 listening

=cut

sub listening {
	my ($self) = @_;
	return $self->{listening} if exists $self->{listening};

	defined(my $path = $self->path) or die "No path provided";
	unlink $path or die "Unable to remove existing $path socket - $!" if -S $path;

	my $f = $self->loop->new_future->set_label('listener startup');
	$self->{listening} = $f;
	my $listener = IO::Async::Listener->new(
		on_accept => $self->curry::incoming_socket,
	);

	$self->add_child($listener);
	$listener->listen(
		addr => {
			family      => 'unix',
			socktype    => 'stream',
			path        => $self->path,
		},

		on_listen => $self->curry::on_listen_start($f),
		# on_stream => $self->curry::incoming_stream,

		on_listen_error => sub {
			$f->fail(listen => "Cannot listen - $_[1]\n");
		},
	);
	$f
}

=head2 on_listen_start

=cut

sub on_listen_start {
	my ($self, $f, $listener) = @_;

	my $sock = $listener->read_handle;

	# Make sure the socket is accessible
	if(my $mode = $self->mode) {
		# Allow octal-as-string
		$mode = oct $mode if substr($mode, 0, 1) eq '0';
		$self->debug_printf("chmod %s to %04o", $self->path, $mode);
		chmod $mode, $self->path or $f->fail(listen => 'unable to chmod socket - ' . $!);
	}

	# Support custom backlog (default 1 is usually too low)
	if(my $backlog = $self->backlog) {
		$self->debug_printf("Set listen queue on %s to %d", $self->path, $backlog);
		$sock->listen($backlog) or die $!;
	}

	$f->done($listener);
}

=head2 incoming_socket

Called when we have an incoming socket. Usually indicates a new request.

=cut

sub incoming_socket {
	my ($self, $listener, $socket) = @_;
	$self->debug_printf("Incoming socket - %s, total now ", $socket, 0+$self->children);

	$socket->blocking(0);
	my $stream = Net::Async::UWSGI::Server::Connection->new(
		handle     => $socket,
		bus        => $self->bus,
		on_request => $self->{on_request},
		autoflush  => 1,
	);
	$self->add_child($stream);
}

=head2 bus

The event bus. See L<Mixin::Event::Dispatch::Bus>.

=cut

sub bus { shift->{bus} ||= Mixin::Event::Dispatch::Bus->new }

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2013-2015. Licensed under the same terms as Perl itself.
