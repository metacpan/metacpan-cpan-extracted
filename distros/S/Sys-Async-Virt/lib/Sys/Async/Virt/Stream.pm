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
use Object::Pad 0.821;

class Sys::Async::Virt::Stream v0.2.1;

use Carp qw(croak);
use Future;
use Future::Queue;
use Log::Any qw($log);

use Protocol::Sys::Virt::Remote::XDR v11.10.1;
my $remote = 'Protocol::Sys::Virt::Remote::XDR';

field $_id :param :reader;
field $_proc :param :reader;
field $_client :param :reader;
field $_direction :param :reader;
field $_max_items :param :reader = 5;
field $_pending_error = undef;
field $_finished = Future->new;
field $_queue = Future::Queue->new;

async method receive() {
    if ($_direction eq 'send') {
        die "Receive called on sending stream (id: $self->{id}";
    }
    if (my $e = $_pending_error) {
        $_pending_error = undef;
        die $e;
    }

    return { data => '' } if $_finished->is_ready; # stop all reads
    return await $_queue->shift;
}

async method _dispatch_receive($data, $final) {
    return if $_finished->is_ready; # discard all input
    if ($final) {
        $_finished->done;
        return;
    }
    if ($_direction eq 'send') {
        die;
    }

    # throttle receiving if the queue gets too long
    await $_queue->push($data);
    return;
}

async method _dispatch_error($error) {
    return if $_finished->is_ready; # discard all input
    $_finished->done;
    unless ($_pending_error) {
        $_pending_error = $error;
    }
    return;
}

async method send($data, $offset = 0, $length = undef) {
    if ($_direction eq 'receive') {
        die "'send' called on receiving stream (id: $self->{id}";
    }
    if (my $e = $_pending_error) {
        $_pending_error = undef;
        die $e;
    }
    return if $_finished->is_ready; # discard all transfers

    my $chunk = ($offset or $length) ? substr($data, $offset, $length) : $data;
    return await $_client->_send(
        $_proc, $_id,
        data => $chunk );
}

async method send_hole($length, $flags = 0) {
    if ($_direction eq 'receive') {
        die "'send_hole' called on receiving stream (id: $self->{id}";
    }
    if (my $e = $_pending_error) {
        $_pending_error = undef;
        die $e;
    }

    return if $_finished->is_ready; # discard all transfers
    return await $_client->_send(
        $_proc, $_id,
        hole => { length => $length, flags => $flags } );
}

async method abort() {
    return if $_finished->is_ready;
    $_client->_send_finish( $_finished, $_proc, $_id, 1 );
    await $_finished;

    $self->cleanup;
    if (my $e = $_pending_error) {
        $_pending_error = undef;
        die $e;
    }
    return;
}

method cleanup() {
    $_queue = undef;
    $_finished->done
        unless $_finished->is_ready;

    return;
}

async method finish() {
    return if $_finished->is_ready;
    $_client->_send_finish( $_finished, $_proc, $_id, 0 );
    await $_finished;

    $self->cleanup;
    if (my $e = $_pending_error) {
        $_pending_error = undef;
        die $e;
    }
    return;
}

method DESTROY() {
    if (not $_finished->is_ready) {
        # abort the stream
        $_client->_send_finish( undef, $_proc, $_id, 1 );
    }
}

1;

__END__

=head1 NAME

Sys::Async::Virt::Stream - Client side of a data transfer channel

=head1 VERSION

v0.2.1

=head1 SYNOPSIS

  use Future::AsyncAwait;

  my $dom = await $virt->domain_lookup_by_name( 'domain-1' );
  my ($mime, $stream) = await $dom->screenshot( 0 ); # 0 = screen number

  try {
    while ( my $data = await $stream->receive ) {
      if ($data->{data}) {
        # process the received data
      }
      elsif ($data->{hole}) {
        # process a hole in the input data
      }
      else {
        # $data->{data} eq '' --> end-of-stream
        last;
      }
    }
  }
  catch ($e) {
    await $stream->abort;
  }

  await $stream->finish;

=head1 DESCRIPTION

A stream models a uni-directional data transfer channel. They are used to
upload and download the content of storage volumes, during migration of
guests among others.

=head1 EVENTS

=head1 CONSTRUCTOR

=head2 new

The constructor takes the following arguments:

=over 8

=item * id

=item * proc

=item * client

=item * direction

=item * max_items

=back

=head1 DESTRUCTOR

=head2 DESTROY

  $stream = undef;

Aborts the stream, if it hasn't already been terminated.

=head1 ATTRIBUTES

=head2 direction

Can have one of two values; either C<send> or C<receive>.

=head1 METHODS

=head2 abort

  await $stream->abort;
  # -> (* no data *)

Terminates stream data transfer indicating an error condition
on the client.

=head2 finish

  await $stream->finish;
  # -> (* no data *)

Terminates stream data transfer indicating success.

=head2 receive

  await $stream->receive;
  # -> { data => $data }
  # or:
  # -> { hole => { length => $length, flags => $flags } }

Applicable to C<receive> direction streams. When called on C<send> direction
streams, throws an exception.

=head2 send

  await $stream->send( $data );
  # -> (* no data *)

Applicable to C<send> direction streams. When called on C<receive> direction
streams, throws an exception.

=head2 send_hole

  await $stream->send_hole( $length, $flags = 0 );
  # -> (* no data *)

Applicable to C<send> direction streams. When called on C<receive> direction
streams, throws an exception.

=head1 INTERNAL METHODS

=head2 _dispatch_error

=head2 _dispatch_receive

=head1 SEE ALSO

L<LibVirt|https://libvirt.org>, L<Sys::Virt>

=head1 LICENSE AND COPYRIGHT


  Copyright (C) 2024-2025 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
