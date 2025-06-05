####################################################################
#
#     This file was generated using XDR::Parse version v0.3.1
#                   and LibVirt version v11.4.0
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

package Sys::Async::Virt::Stream v0.0.20;

use parent qw( IO::Async::Notifier );

use Carp qw(croak);
use Future::Queue;
use Log::Any qw($log);

use Protocol::Sys::Virt::Remote::XDR v0.0.20;
my $remote = 'Protocol::Sys::Virt::Remote::XDR';

sub new($class, %args) {
    return bless {
        id => $args{id},
        proc => $args{proc},
        client => $args{client},
        direction => $args{direction},
        max_items => $args{max_items},
        pending_error => undef,
    }, $class;
}

sub _add_to_loop($self, $loop) {
    $self->{finished} = $loop->new_future;
    $self->{queue}    = Future::Queue->new(
        prototype => sub { $self->new_future },
        max_items => $self->{max_items},
        );
    $self->SUPER::_add_to_loop($loop);
}

sub direction($self) {
    return $self->{direction};
}

async sub receive($self) {
    if ($self->{direction} eq 'send') {
        die "Receive called on sending stream (id: $self->{id}";
    }
    if (my $e = $self->{pending_error}) {
        $self->{pending_error} = undef;
        die $e;
    }

    return { data => '' } if $self->{finished}->is_ready; # stop all reads
    await $self->{queue}->shift;
}

async sub _dispatch_receive($self, $data, $final) {
    return if $self->{finished}->is_ready; # discard all input
    if ($final) {
        $self->{finished}->done;
        return;
    }
    if ($self->{direction} eq 'send') {
        die;
    }

    # throttle receiving if the queue gets too long
    await $self->{queue}->push($data);
}

async sub _dispatch_error($self, $error) {
    return if $self->{finished}->is_ready; # discard all input
    $self->{finished}->done;
    unless ($self->{pending_error}) {
        $self->{pending_error} = $error;
    }
    return;
}

async sub send($self, $data, $offset = 0, $length = undef) {
    if ($self->{direction} eq 'receive') {
        die "'send' called on receiving stream (id: $self->{id}";
    }
    if (my $e = $self->{pending_error}) {
        $self->{pending_error} = undef;
        die $e;
    }
    return if $self->{finished}->is_ready; # discard all transfers

    return await $self->{client}->_send(
        $self->{proc}, $self->{id},
        data => ($offset or $length) ? substr($data, $offset, $length) : $data );
}

async sub send_hole($self, $length, $flags = 0) {
    if ($self->{direction} eq 'receive') {
        die "'send_hole' called on receiving stream (id: $self->{id}";
    }
    if (my $e = $self->{pending_error}) {
        $self->{pending_error} = undef;
        die $e;
    }

    return if $self->{finished}->is_ready; # discard all transfers
    return await $self->{client}->_send(
        $self->{proc}, $self->{id},
        hole => { length => $length, flags => $flags } );
}

async sub abort($self) {
    await $self->{client}->_send_finish( $self->{proc}, $self->{id}, 1 );
    await $self->{finished};

    $self->cleanup;
    if (my $e = $self->{pending_error}) {
        $self->{pending_error} = undef;
        die $e;
    }
    return;
}

sub cleanup($self) {
    delete $self->{_streams}->{$self->{id}};
    $self->remove_from_parent;
    $self->{queue} = undef;
    $self->{finished}->done
        unless $self->{finished}->is_ready;

    return;
}

async sub finish($self) {
    await $self->{client}->_send_finish( $self->{proc}, $self->{id}, 0 );
    await $self->{finished};

    $self->cleanup;
    if (my $e = $self->{pending_error}) {
        $self->{pending_error} = undef;
        die $e;
    }
    return;
}

sub DESTROY($self) {
    if (not $self->{finished}->is_ready) {
        $self->abort->retain;
    }
}

1;

__END__

=head1 NAME

Sys::Async::Virt::Stream - Client side of a data transfer channel

=head1 VERSION

v0.0.20

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

Instances have L<IO::Async::Notifier> mixed in because they need access to
awaitable futures.  C<$self->loop->new_future> provides that access.

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
