####################################################################
#
#     This file was generated using XDR::Parse version v1.0.1
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

class Sys::Async::Virt::Connection::Process v0.2.3;

inherit Sys::Async::Virt::Connection '$_in', '$_out';

use Carp qw(croak);
use Future::IO;
use IO::Handle;
use IPC::Open2;
use Log::Any qw($log);

use Protocol::Sys::Virt::URI v11.10.1; # imports parse_url

field $_url :param :reader;
field $_pid;
field $_exit_f;

async method close() {
    unless ($_exit_f->is_ready) {
        kill 'TERM', $_pid;
    }
    ### TODO: log exit status
    await $_exit_f;
}

method _command( $url ) {
    my %c = parse_url( $url );
    return $c{command};
}

async method connect() {
    my @cmd = $self->_command( $_url );
    $log->trace('Connection process command: ' . join(' ', @cmd));

    $_pid = open2( $_in, $_out, @cmd )
        or die "Unable to open external command: $!";
    $_out->autoflush( 1 );
    $_out->blocking( 0 );
    $_in->autoflush( 1 );
    $_in->blocking( 0 );
    $_exit_f = Future::IO->waitpid( $_pid );

    return;
}

1;


__END__

=head1 NAME

Sys::Async::Virt::Connection::Process - Connection to LibVirt server using
  an external process

=head1 VERSION

v0.2.3

=head1 SYNOPSIS

  use v5.26;
  use Future::AsyncAwait;
  use Sys::Async::Virt::Connection::Factory;

  my $factory = Sys::Async::Virt::Connection::Factory->new;
  my $conn    = $factory->create_connection( 'qemu+ext:///system?cmd=/bin/true' );

=head1 DESCRIPTION

This module connects to a local LibVirt server through an external command
which forwards standard input to and standard output from the LibVirt server.

B< NOTE > This module requires the C<< Future::IO->waitpid >> call to work,
which the default implementation does not provide. Any of the other backends
listed in L<Future::IO> needs to be active for this module to work.

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
