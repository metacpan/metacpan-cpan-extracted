####################################################################
#
#     This file was generated using XDR::Parse version v0.3.1
#                   and LibVirt version v11.10.0
#
#      Don't edit this file, use the source template instead
#
#                 ANY CHANGES HERE WILL BE LOST !
#
####################################################################


use v5.26;
use warnings;
use experimental 'signatures';
use Future::AsyncAwait;
use Object::Pad ':experimental(inherit_field)';

class Sys::Async::Virt::Connection::Local v0.2.1;

inherit Sys::Async::Virt::Connection '$_in', '$_out';

use Carp qw(croak);
use Future::IO;
use IO::Socket;
use IO::Socket::UNIX;
use Log::Any qw($log);

field $_url :param :reader;
field $_readonly :param = undef;
field $_socket :param = undef;

async method close() {
    # Work around for Future::IO which doesn't
    # like handles being closed when there are
    # outstanding read/write requests (causing
    # warnings of undefined values)
    $self->_finalize_io();
    # When Future::IO and/or IO::Async are changed
    # (ready_for_input() is where this happens),
    # the handle *can* be closed.
    # $_in->close;
    return;
}

async method connect() {
    # disect URL
    $_socket //=
        '/run/libvirt/libvirt-sock' . ($_readonly ? '-ro' : '');

    my $sock = IO::Socket->new(
        Domain => AF_UNIX,
        Type => SOCK_STREAM,
        );
    binmode $sock, ':bytes';
    $sock->blocking( 0 );

    $_in = $_out = $sock;
    my $addr = sockaddr_un( $_socket );
    await Future::IO->connect( $sock, $addr );
}

method is_secure() {
    return 1;
}

1;


__END__

=head1 NAME

Sys::Async::Virt::Connection::Local - Connection to LibVirt server over Unix
 domain sockets

=head1 VERSION

v0.2.1

=head1 SYNOPSIS

  use v5.26;
  use Future::AsyncAwait;
  use Sys::Async::Virt::Connection::Factory;

  my $factory = Sys::Async::Virt::Connection::Factory->new;
  my $conn    = $factory->create_connection( 'qemu:///system' );

=head1 DESCRIPTION

This module connects to a local LibVirt server through a Unix domain
socket.

=head1 URL PARAMETERS

This connection driver supports these parameters in the query string
of the URL, as per L<LibVirt's documentation|https://libvirt.org/uri.html#unix-transport>:

=over 8

=item * mode

=item * socket (todo)

The path of the socket to be connected to.

=back

=head1 CONSTRUCTOR

=head2 new

Not to be called directly. Instantiated via the connection factory
(L<Sys::Async::Virt::Connection::Factory>).

=head1 METHODS

=head2 connect

  await $conn->connect;

=head2 is_secure

  my $bool = $conn->is_secure;

Returns C<true>.

=head1 SEE ALSO

L<LibVirt|https://libvirt.org>, L<Sys::Virt>

=head1 LICENSE AND COPYRIGHT


  Copyright (C) 2024-2025 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
