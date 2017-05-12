package Simulation::DiscreteEvent::Recorder;

use Moose::Role;
our $VERSION = '0.09';

=head1 NAME

Simulation::DiscreteEvent::Recorder - Moose role for recording all events for server

=head1 SYNOPSIS

Add Simulation::DiscreteEvent::Recorder role to your server:

    package MyServer;
    use Moose;
    BEGIN { extends 'Simulation::DiscreteEvent::Server'; }
    with 'Simulation::DiscreteEvent::Recorder';
    sub handler1 : Event(start) {
        # handle start event here
    }
    sub handler2 : Event(stop) {
        # handle stop event here
    }

Then after running simulation you can get information about moments of the
events, intervals between events, etc:

    my @events = $server->get_all_events;
    my $started = $server->get_number_of('start');
    my @started_at = $server->get_moments_of('start');
    my @stop_intvl = $server->intervals_between('stop');

=head1 DESCRIPTION

This role allows you to record information about every event during simulation.

=head1 METHODS

The following methods are added to the class that uses that role

=cut

requires 'model';

=head2 $self->get_all_events

Returns list of all events handled by this server. Every item in the list is
refference to array with two elements: time the event has occured, and name of
the event.

=cut
has _recorder_events => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        _recorder_add_event => 'push',
        get_all_events      => 'elements',
    }
);

before handle => sub {
    my $self = shift;
    $self->_recorder_add_event( [ $self->model->time, $_[0] ] );
};

=head2 $self->get_number_of([$event])

Returns how many times I<$event> has occured. If I<$event> is not specified
returns total number of the events.

=cut
sub get_number_of {
    my $self = shift;
    my $res = 0;
    if(@_) {
        my $event = shift;
        for (@{$self->_recorder_events}) {
            $res++ if $_->[1] eq $event;
        }
    }
    else {
        $res = @{$self->_recorder_events};
    }
    $res;
}

=head2 $self->get_moments_of([$event])

Returns list of moments at which I<$event> has occured. If I<$event> is not
specified returns moments of all events.

=cut
sub get_moments_of {
    my $self = shift;
    if (@_) {
        my $event = shift;
        return map { $_->[0] } grep { $_->[1] eq $event } @{$self->_recorder_events};
    }
    else {
        return map { $_->[0] } @{$self->_recorder_events};
    }
}

=head2 $self->intervals_between([$event])

Returns intervals between subsequent moments when I<$event> has occured. As for
previous function, if I<$event> is missed uses all events.

=cut
sub intervals_between {
    my $self = shift;
    my @moments = $self->get_moments_of(@_);
    my $prev = shift @moments;
    ($_, $prev) = ($_-$prev, $_) for @moments;
    @moments;
}

1;

__END__


=head1 AUTHOR

Pavel Shaydo, C<< <zwon at cpan.org> >>

=head1 SUPPORT

Please see documentation for L<Simulation::DiscreteEvent>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Pavel Shaydo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

