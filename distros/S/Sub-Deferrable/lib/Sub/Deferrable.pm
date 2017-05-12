package Sub::Deferrable;

use warnings;
use strict;

=head1 NAME

Sub::Deferrable - Optionally queue sub invocations for later.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use Sub::Deferrable;
    my $queue = Sub::Deferrable->new();
    my $sub  = $queue->make_deferrable( \&some_sub );
    $sub->(@args);              # Executes immediately
    $queue->defer;
    $sub->(@more_args);         # Not executed
    $sub->(@yet_more_args);     # Not executed
    $queue->undefer;            # Both calls now executed synchronously;
                                # subsequent calls execute immediately.

Sub::Deferrable provides methods for wrapping a sub reference,
giving it a split personality. In "normal" mode the wrapper simply
calls the sub, passing along any arguments. In "deferred" mode, the
wrapper creates an invocation object and saves it on a queue. When
the queue is returned to "normal" mode, all invocations on the queue
are executed immediately.

=head1 EXPORT

No exports.

=head1 METHODS

=head2 new

Returns a new Sub::Deferrable object with an empty queue.

=cut

sub new {
    my $class = shift;
    my $self  = { deferring => 0, queue => [] };
    bless $self, $class;
    return $self;
}

=head2 $self->mk_deferrable( \&some_sub )

Returns a new sub reference, which normally behaves like \&some_sub, but
which saves an invocation of \&some_sub on the queue when in "deferred"
mode.

An optional extra argument provides a sub reference to be applied
to the invocation arguments I<at queueing time>. If this argument
is supplied, it is probably a reference to C<Storable::dclone>,
which will create a deep copy of the arguments and so break any
reference pointers. This might be needed if, say, the arguments at
invocation time might change before the queued sub is run.

=cut

sub mk_deferrable {
    my $self        = shift;
    my $sub         = shift;
    my $transform   = shift || sub {return shift};
    sub {
        my $args = @_ ? $transform->(\@_) : undef;
        if ($self->deferring) {
            push @{$self->{queue}}, [$sub, $args];
        }
        else {
            defined $args ? $sub->(@$args) : $sub->();
        }
    };
}

=head2 $self->deferring

Returns I<true> when deferrable subs are queued; I<false> when they are
than invoked immediately.

=cut

sub deferring {
    my $self = shift;
    return $self->{deferring};
}

=head2 $self->defer

Stop executing deferrable subs, and start queueing them instead. Repeated
calls to $self->defer are equivalent to a single call; in particular, one
call to $self->undefer will turn off deferral mode.

=cut

sub defer {
    my $self = shift;
    $self->{deferring} = 1;
}

=head2 $self->undefer

Stop queueing subs, and start executing them immediately. Any subs already
queued are executed before undefer() returns.

=cut

sub undefer {
    my $self = shift;
    $self->{deferring} = 0;
    return unless @{$self->{queue}};

    # This tortured way of doing the loop is (surpringly) significantly faster.
    my $died = 0;
    my $final_idx = $#{$self->{queue}};
    for my $idx (0..$#{$self->{queue}}) {
        my ($sub, $args) = @{$self->{queue}[$idx]};

        # Only way to return false is to die...
        my $status = eval { defined $args ? $sub->(@$args) : $sub->(); 1 };
        do { $died = 1; $final_idx = $idx; last } unless $status;
    }

    splice @{$self->{queue}}, 0, $final_idx+1;
    die $@ if $died;

    return;
}

=head2 $self->cancel

Stop queueing subs, but discard any subs already queued.

=cut

sub cancel {
    my $self = shift;
    $self->{queue} = [];
    $self->undefer;
}

=head2 DESTROY

On destruction, all queued subs are invoked. This is a failsafe;
please do not write code that relies on this behavior. By the time
this object is destroyed, it's likely too late to invoke your subs
anyway, so this will probably crash your app. As you so richly
deserve.

=cut

sub DESTROY {
    my $self = shift;
    $self->undefer;
}

=head1 AUTHOR

Budney, Len, C<< <Budney.Len@grantstreet.com> >>

=head1 BUGS

Not all subs are deferrable, by their nature. If the sub interacts
with an open file or socket, for example, execution may fail later
because the file or socket is closed. Presumably, you thought of
that before you decided to make your sub deferrable.


=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005-2012 Grant Street Group. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Sub::Deferrable
