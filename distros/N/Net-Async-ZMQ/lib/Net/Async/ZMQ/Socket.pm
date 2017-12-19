package Net::Async::ZMQ::Socket;
# ABSTRACT: Use a ZMQ socket asynchronously using IO::Async
$Net::Async::ZMQ::Socket::VERSION = '0.001';
use strict;
use warnings;

use Package::Stash;

use ZMQ::Constants qw(ZMQ_FD);
use Fcntl qw(O_RDONLY);
use if $^O eq 'MSWin32', 'Win32API::File' => qw(OsFHandleOpenFd);

use base qw( IO::Async::Handle );

sub configure {
	my ($self, %params) = @_;

	for (qw(socket)) {
		$self->{$_} = delete $params{$_} if exists $params{$_};
	}


	if( exists $self->{socket} ) {
		my $zmq_libzmq_class;
		my $socket = $self->{socket};
		if( $socket->isa('ZMQ::LibZMQ3::Socket') ) {
			$zmq_libzmq_class = 'ZMQ::LibZMQ3';
		} elsif( $socket->isa('ZMQ::LibZMQ4::Socket') ) {
			$zmq_libzmq_class = 'ZMQ::LibZMQ4';
		} else {
			die "Unknown ZMQ socket: $socket";
		}

		$self->{_stash} = Package::Stash->new($zmq_libzmq_class);

		$params{read_handle} = $self->_zmq_get_io_handle($self->{socket});

	}

	$self->SUPER::configure(%params);
}

sub socket {
	my ($self) = @_;
	$self->{socket};
}

sub _zmq_get_io_handle {
	my ($self, $socket) = @_;

	my $zmq_getsockopt = $self->{_stash}->get_symbol('&zmq_getsockopt');
	my $zmq_getsockopt_uint64 = $self->{_stash}->get_symbol('&zmq_getsockopt_uint64');

	my $fd;

	if( $^O eq 'MSWin32' ) {
		# `SOCKET` data type is a `uint64` on Windows x64.
		my $socket_handle = $zmq_getsockopt_uint64->( $socket, ZMQ_FD );
		# Converts OS socket handle to a C runtime file descriptor.
		$fd = OsFHandleOpenFd($socket_handle, O_RDONLY);
	} else {
		$fd = $zmq_getsockopt->( $socket, ZMQ_FD );
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

version 0.001

=head1 DESCRIPTION

A subclass of L<IO::Async::Handle> that works with ZMQ sockets.

It currently handles sockets from both L<ZMQ::LibZMQ3> and L<ZMQ::LibZMQ4> on
both Unix-like systems and Windows.

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

  InstanceOf['ZMQ::LibZMQ3::Socket'] | InstanceOf['ZMQ::LibZMQ4::Socket']

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
