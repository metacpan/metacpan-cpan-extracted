package Promises::Channel;
# ABSTRACT: a coordination channel implemented with Promises
$Promises::Channel::VERSION = '0.04';

use strict;
use warnings;

use Moo;
use Promises qw(deferred);

extends 'Exporter';

our @EXPORT_OK = qw(
  channel
  chan
);



has limit =>
  is        => 'ro',
  predicate => 'has_limit';


has shutdown_signal =>
  is      => 'ro',
  default => sub { deferred },
  handles => { is_shutdown => 'is_done' };

#-------------------------------------------------------------------------------
# Stores pending insertions as a list of tuples in the form of [item, promise].
# When the inbox is full, this is where callers of put() wait until there is
# room for their item to be inserted.
#-------------------------------------------------------------------------------
has backlog =>
  is      => 'ro',
  default => sub { [] };

#-------------------------------------------------------------------------------
# Stores inserted items ready for delivery.
#-------------------------------------------------------------------------------
has inbox =>
  is      => 'ro',
  default => sub { [] };

#-------------------------------------------------------------------------------
# Stores a list of promises handed out by get, representing callers that are
# waiting for items in the queue.
#-------------------------------------------------------------------------------
has outbox =>
  is      => 'ro',
  default => sub { [] };


sub size {
  my $self = shift;
  scalar @{ $self->inbox };
}


sub is_full {
  my $self = shift;
  return $self->has_limit
      && $self->size == $self->limit;
}


sub is_empty {
  my $self = shift;
  return $self->size == 0
      && !@{ $self->backlog };
}


sub put {
  my ($self, $item) = @_;
  my $soon = deferred;

  my $promise = $soon->then(sub {
    $self->drain;
    return $self;
  });

  push @{ $self->backlog }, [$item, $soon];
  $self->pump;
  return $promise;
}


sub get {
  my $self = shift;
  my $soon = deferred;

  my $promise = $soon->then(sub {
    my ($self, $item) = @_;
    $self->pump;
    return ($self, $item);
  });

  push @{ $self->outbox }, $soon;
  $self->drain;
  return $promise;
}


sub shutdown {
  my $self = shift;
  $self->shutdown_signal->resolve
    unless $self->is_shutdown;
  $self->drain;
  $self->pump;
}


sub on_shutdown {
  my $self = shift;
  return $self->shutdown_signal->promise;
}


#-------------------------------------------------------------------------------
# Clears out waiting backlog of insertions until the queue is full.
#-------------------------------------------------------------------------------
sub pump {
  my $self = shift;

  while (@{ $self->backlog } && !$self->is_full) {
    my ($item, $soon) = @{ shift @{ $self->backlog } };
    push @{ $self->inbox }, $item;
    $soon->resolve($self->size);
  }
}

#-------------------------------------------------------------------------------
# Drains the queue (inbox) and resolves waiting watchers' promises (outbox) to
# the next item in the queue until empty. If shutdown has been called, any
# further watchers are resolved to undef.
#-------------------------------------------------------------------------------
sub drain {
  my $self = shift;

  while (@{ $self->inbox } && @{ $self->outbox }) {
    my $soon = shift @{ $self->outbox };
    my $msg  = shift @{ $self->inbox };
    $soon->resolve($self, $msg);
  }

  if ($self->is_shutdown) {
    while (my $soon = shift @{ $self->outbox }) {
      $soon->resolve($self, undef);
    }
  }

  return;
}

#-------------------------------------------------------------------------------
# Automatically shuts down the channel when the instance goes out of scope or
# is destroyed.
#-------------------------------------------------------------------------------
sub DEMOLISH {
  my $self = shift;
  $self->shutdown;
}



sub channel { Promises::Channel->new(@_) }
sub chan    { Promises::Channel->new(@_) }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Promises::Channel - a coordination channel implemented with Promises

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  # See notes about recursion in Promises::Cookbook::Recursion
  use Promises backend => ['AE'], 'deferred';
  use Promises::Channel qw(channel);

  my $channel = channel
    limit => 4;


  # Use $channel to invert control on an AnyEvent::Handle
  $ae_handle->on_read(sub {
    my $handle = shift;

    $handle->push_read(line => sub {
      my ($handle, $line) = @_;
      $channel->put($line);
    });
  });

  $ae_handle->on_error(sub {
    $channel->shutdown;
  });

  my $depleted = 0;
  $channel->on_shutdown
    ->then(sub { $depleted = 1 });

  sub reader {
    my ($channel, $line) = @_;
    do_stuff $line;

    # Queue the next read, using done to avoid recursion
    $channel->get->done(\&reader);
  }

  $channel->get->then(\&reader);

=head1 DESCRIPTION

A C<Promises::Channel> is a FIFO queue that produces L<Promises::Promise>s
which resolve to the items added to the queue.

=head1 ATTRIBUTES

=head2 limit

Sets an upper boundary on the number of items which may be queued at a time. If
this limit is reached, the promise returned by the next call to L</put> will
not be resolved until there has been a corresponding call to L</get> (or the
channel has been L</shutdown>.

=head2 is_shutdown

Returns true if the channel has been shutdown. The channel will be
automatically shutdown and drained when demolished.

=head1 METHODS

=head2 size

Returns the number of items in the queue. This number is not adjusted to
reflect any queued waiters.

=head2 is_full

If a L</limit> has been set, returns true if the channel is full and cannot
immediately accept new items.

=head2 is_empty

Returns true if there are no items in the queue and there are no pending
deliveries of items from deferred L</put>s.

=head2 put

Adds one or more items to the channel and returns a L<Promises::Promise> that
will resolve to the channel instance after the item has been added (which may
be deferred if L</limit> has been set).

=head2 get

Returns a L<Promises::Promise> which will resolve to the channel and the next
item queued in the channel.

  $chan->get->then(sub {
    my ($chan, $item) = @_;
    ...
  });

=head2 shutdown

Closes the queue. This does not prevent new items from being added. However,
future calls to L</get> will be resolved immediately with C<undef>. Any
previously deferred calls to get will be immediately resolved until the channel
is empty, after which any remaining deferrals will be resolved with C<undef>.

When the channel goes out of scope, it will be shutdown and drained
automatically.

=head2 on_shutdown

Returns a promise which will be resolved after the channel has been shut down
and drained. As the channel is shut down when demolished, this promise will
be resolved when the channel goes out of scope as well.

=head1 EXPORTS

Nothing is exported by default.

=head2 chan

=head2 channel

Sugar for calling the default constructor. The following lines are equivalent.

  my $ch = chan;
  my $ch = channel;
  my $ch = Promises::Channel->new;

=head1 CONTRIBUTORS

The following people have contributed to this module by supplying new features,
bug reports, or feature requests.

=over

=item Erik Huelsmann (EHUELS)

=back

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
