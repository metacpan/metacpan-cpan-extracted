####################################################################
#
#     This file was generated using XDR::Parse version v0.3.1
#                   and LibVirt version v11.8.0
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
use Object::Pad;

class Sys::Async::Virt::Connection::Process v0.1.7;

inherit Sys::Async::Virt::Connection '$_in', '$_out';

use Carp qw(croak);
use IO::Async::Stream;
use Log::Any qw($log);

use Protocol::Sys::Virt::URI v11.8.0; # imports parse_url

field $_url :param :reader;
field $_process = undef;

method close() {
    $_process->kill( 'TERM' )
        if not $_process->is_exited;
}

method configure(%args) {
    delete $args{url};

    $self->SUPER::configure(%args);
}

async method connect() {
    my %c = parse_url( $_url );

    my $cmd  = $c{command};
    my $process = $self->loop->open_process(
        command => $cmd,
        stdout => {
            on_read => sub { 0 },
        },
        stderr => {
            on_read => sub {
                # eat stderr input
                my $bufref = $_[1]; say $bufref; ${$bufref} = ''; 0;
            },
        },
        stdin => {
            via => 'pipe_write'
        },
        on_finish => sub { }, # on_finish is mandatory
        );

    $_in  = $process->stdout;
    $_out = $process->stdin;

    return;
}

1;


__END__

=head1 NAME

Sys::Async::Virt::Connection::Process - Connection to LibVirt server using
  an external process

=head1 VERSION

v0.1.7

=head1 SYNOPSIS

  use v5.26;
  use Future::AsyncAwait;
  use Sys::Async::Virt::Connection::Factory;

  my $factory = Sys::Async::Virt::Connection::Factory->new;
  my $conn    = $factory->create_connection( 'qemu+ext:///system?cmd=/bin/true' );

=head1 DESCRIPTION

This module connects to a local LibVirt server through an external command
which forwards standard input to and standard output from the LibVirt server.

=head1 URL PARAMETERS

This connection driver supports these parameters in the query string
of the URL, as per L<LibVirt's documentation|https://libvirt.org/uri.html#ext-transport>:

=over 8

=item * command

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

Returns C<false>: there is no guarantee that the external process
is transferring the data securely. As LibVirt's docs put it: we
fail on the safe side.

=head1 SEE ALSO

L<LibVirt|https://libvirt.org>, L<Sys::Virt>

=head1 LICENSE AND COPYRIGHT


  Copyright (C) 2024-2025 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
