####################################################################
#
#     This file was generated using XDR::Parse version v1.0.1
#                   and LibVirt version v12.5.0
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

class Sys::Async::Virt::Connection::TCP v0.6.5;

inherit Sys::Async::Virt::Connection '$_in', '$_out';

use Carp qw(croak);
use Future::IO;
use IO::Socket::IP;
use Log::Any qw($log);

use Protocol::Sys::Virt::URI; # imports parse_url

my $use_async_resolver = eval { require Future::IO::Resolver; 1; };

field $_url :param :reader :inheritable;
field $_readonly :param = undef;
field $_socket :param :inheritable  = undef;


### workaround methods while transitive inheritace doesn't work in Object::Pad
### See: RT#172999

method _set_in($in) {
    $_in = $in;
}

method _set_out($out) {
    $_out = $out;
}

###

method _default_port() {
    return 16509;
}

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
    my %components = parse_url( $_url );

    if ($use_async_resolver) {
        my ($address) = await Future::IO::Resolver->getaddrinfo(
            host => $components{host},
            service => ($components{port} // $self->_default_port),
            socktype => SOCK_STREAM,
            );
        socket( $_socket,
                $address->{family},
                $address->{socktype},
                $address->{protocol} )
            or die;
        await Future::IO->connect( $_socket, $address->{addr} );
    }
    else {
        my ($err, @addresses) = IO::Socket::IP::getaddrinfo(
            $components{host},
            ($components{port} // $self->_default_port),
            { socktype => SOCK_STREAM }
            );
        die $err if $err;

        $_socket = IO::Socket::IP->new(
            Type => SOCK_STREAM,
            PeerAddrInfo => \@addresses,
            )
            or die "Failed to connect socket: $!";
    }

    $_in = $_out = $_socket;
}

method is_secure() {
    return 0;
}

1;


__END__

=head1 NAME

Sys::Async::Virt::Connection::TCP - Connection to LibVirt server over TCP sockets

=head1 VERSION

v0.6.5

=head1 SYNOPSIS

  use v5.26;
  use Future::AsyncAwait;
  use Sys::Async::Virt::Connection::Factory;

  my $factory = Sys::Async::Virt::Connection::Factory->new;
  my $conn    = $factory->create_connection( 'qemu+tcp:///system' );

=head1 DESCRIPTION

This module connects to a remote LibVirt server through a TCP socket. This transport
uses plain unencrypted TCP connection to libvirt, is insecure and should
not be used.

This module requires L<Future::IO::Resolver> to operate fully asynchronous;
in case this module is unavailable, the C<getaddrinfo> function from L<Socket>
is used - which is a blocking function call.

=head1 URL PARAMETERS

This connection driver does not support any additional parameters,
as per L<LibVirt's documentation|https://libvirt.org/uri.html#tcp-transport>.

=head1 CONSTRUCTOR

=head2 new

Not to be called directly. Instantiated via the connection factory
(L<Sys::Async::Virt::Connection::Factory>).

=head1 METHODS

=head2 connect

  await $conn->connect;

=head2 is_secure

  my $bool = $conn->is_secure;

Returns C<false>.

=head1 SEE ALSO

L<LibVirt|https://libvirt.org>, L<Sys::Virt>

=head1 LICENSE AND COPYRIGHT


  Copyright (C) 2024-2026 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
