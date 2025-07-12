####################################################################
#
#     This file was generated using XDR::Parse version v0.3.1
#                   and LibVirt version v11.5.0
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

package Sys::Async::Virt::Connection::Local v0.0.21;

use parent qw(Sys::Async::Virt::Connection);

use Carp qw(croak);
use IO::Async::Stream;
use Log::Any qw($log);

sub new($class, $url, %args) {
    return bless {
        url => $url,
        %args{ qw( readonly socket ) }
    }, $class;
}

sub close($self) {
    $self->{in}->close;
}

async sub connect($self) {
    # disect URL
    $self->{socket} //=
        '/run/libvirt/libvirt-sock' . ($self->{readonly} ? '-ro' : '');
    my $sock = await $self->loop->connect(
        addr => {
            family => 'unix',
            socktype => 'stream',
            path => $self->{socket}
        });

    $self->{in} = $self->{out} = IO::Async::Stream->new(
        handle => $sock,
        on_read => sub { 0 }
        );
    $self->add_child( $self->{in} );

    return;
}

sub is_secure($self) {
    return 1;
}

1;


__END__

=head1 NAME

Sys::Async::Virt::Connection::Local - Connection to LibVirt server over Unix
 domain sockets

=head1 VERSION

v0.0.21

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

=item * mode (todo)

=item * socket

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
