package Net::Async::ZMQ::Socket;
# ABSTRACT: Use a ZMQ socket asynchronously using IO::Async
$Net::Async::ZMQ::Socket::VERSION = '0.002';
use strict;
use warnings;

use Package::Stash;

use Module::Load;
use Fcntl qw(O_RDONLY);
use if $^O eq 'MSWin32', 'Win32API::File' => qw(OsFHandleOpenFd);

use base qw( IO::Async::Handle );

sub configure {
	my ($self, %params) = @_;

	for (qw(socket)) {
		$self->{$_} = delete $params{$_} if exists $params{$_};
	}


	if( exists $self->{socket} ) {
		my $zmq_class;
		my $zmq_fd;

		my $socket = $self->{socket};
		if( $socket->isa('ZMQ::LibZMQ3::Socket') ) {
			$self->{_zmq_class} = 'ZMQ::LibZMQ3';
			load 'ZMQ::Constants', qw(ZMQ_FD);
			$zmq_fd = ZMQ::Constants::ZMQ_FD();
		} elsif( $socket->isa('ZMQ::LibZMQ4::Socket') ) {
			$self->{_zmq_class} = 'ZMQ::LibZMQ4';
			load 'ZMQ::Constants', qw(ZMQ_FD);
			$zmq_fd = ZMQ::Constants::ZMQ_FD();
		} elsif( $socket->DOES('ZMQ::FFI::SocketRole') ) {
			$self->{_zmq_class} = 'ZMQ::FFI';
			load 'ZMQ::FFI::Constants', qw(ZMQ_FD);
			$zmq_fd = ZMQ::FFI::Constants::ZMQ_FD();
		} else {
			die "Unknown ZMQ socket: $socket";
		}

		$self->{_stash} = Package::Stash->new($self->{_zmq_class});

		$params{read_handle} = $self->_zmq_get_io_handle($self->{socket}, $zmq_fd);
	}

	$self->SUPER::configure(%params);
}

sub socket {
	my ($self) = @_;
	$self->{socket};
}

sub _zmq_get_io_handle {
	my ($self, $socket, $zmq_fd) = @_;

	my $zmq_getsockopt =
		$self->{_zmq_class} eq 'ZMQ::FFI'
		? sub { my ($socket, $opt) = @_; $socket->get( $opt, 'int' ) }
		: $self->{_stash}->get_symbol('&zmq_getsockopt');
	my $zmq_getsockopt_uint64 =
		$self->{_zmq_class} eq 'ZMQ::FFI'
		? sub { my ($socket, $opt) = @_; $socket->get( $opt, 'uint64_t' ) }
		: $self->{_stash}->get_symbol('&zmq_getsockopt_uint64');

	my $fd;

	if( $^O eq 'MSWin32' ) {
		# `SOCKET` data type is a `uint64` on Windows x64.
		my $socket_handle = $zmq_getsockopt_uint64->( $socket, $zmq_fd );
		# Converts OS socket handle to a C runtime file descriptor.
		$fd = OsFHandleOpenFd($socket_handle, O_RDONLY);
	} else {
		$fd = $zmq_getsockopt->( $socket, $zmq_fd );
	}

	# Use dup() on the ZMQ file descriptor so that Perl can close the
	# handle without closing the ZMQ handle.
	#
	# Also, avoid using IO::Handle here due to how it closes the file
	# handle automatically.
	open(my $io_handle, "<&", $fd);

	$io_handle;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::ZMQ::Socket - Use a ZMQ socket asynchronously using IO::Async

=head1 VERSION

version 0.002

=head1 DESCRIPTION

A subclass of L<IO::Async::Handle> that works with ZMQ sockets.

It currently handles sockets from L<ZMQ::LibZMQ3>, L<ZMQ::LibZMQ4>, and
L<ZMQ::FFI> on both Unix-like systems and Windows.

=head1 EXTENDS

=over 4

=item * L<IO::Async::Handle>

=back

=head1 METHODS

=head2 configure

  method configure( %params )

=head2 socket

  method socket()

Returns the underlying ZMQ socket. See the C<socket> parameter.

=head1 PARAMETERS

=head2 socket

A ZMQ socket.

Takes the type

  InstanceOf['ZMQ::LibZMQ3::Socket']
  | InstanceOf['ZMQ::LibZMQ4::Socket']
  | ConsumerOf['ZMQ::FFI::SocketRole']

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
