package Simulation::DiscreteEvent::NumericState;

use Moose::Role;
our $VERSION = '0.09';

=head1 NAME

Simulation::DiscreteEvent::NumericState - Moose role for recording statistics about server load

=head1 SYNOPSIS

Add Simulation::DiscreteEvent::NumericState role to your server:

    package MyServer;
    use Moose;
    BEGIN { extends 'Simulation::DiscreteEvent::Server'; }
    with 'Simulation::DiscreteEvent::NumericState';
    sub handler1 : Event(start) {
        # handle start event here

        # set state
        $self->state(1);
    }
    sub handler2 : Event(stop) {
        # handle stop event here

        # set state
        $self->state(0);
    }

Then after running simulation you can get information about state changes
during simulation:

    my @state_changes = $server->state_data;
    my $average_load  = $server->average_load;

=head1 DESCRIPTION

This role allows you to record statistic information about server state
during simulation. It also provides simple functions to get some summary of
collected data.

=head1 METHODS

=cut

requires 'model';

=head2 $self->state_data

Returns array with collected data. Each array item is reference to array with
two elements - time of the state change and the new state value.

=cut
has state_data => (
    is         => 'ro',
    isa        => 'ArrayRef[ArrayRef[Num]]',
    default    => sub { [[0, 0],] },
    auto_deref => 1,
    traits     => ['Array'],
    handles    => {
        _add_state => 'push',
    },
);

has _last_state_update_time => ( is => 'rw', isa => 'Num', default => 0, );
has _state => ( is => 'rw', isa => 'Num', default => 0, );
has _cummulative_load => ( is => 'rw', isa => 'Num', default => 0, );

=head2 $self->state([$state])

Allows to set/get server state. Automatically updates statistic data.

=cut
sub state {
    my ( $self, $state ) = @_;
    if ( defined $state ) {
        my $mtime      = $self->model->time;
        my $load_delta
            = ( $mtime - $self->_last_state_update_time ) * $self->_state;
        $self->_cummulative_load( $load_delta + $self->_cummulative_load );
        $self->_add_state( [ $mtime, $state ] );
        $self->_last_state_update_time($mtime);
        return $self->_state($state);
    }
    $self->_state;
}

=head2 $self->state_inc

Increases state by 1. Returns result state.

=cut
sub state_inc {
    my $self = shift;
    $self->state( $self->state + 1 );
}

=head2 $self->state_dec

Decreases state by 1. Returns result state.

=cut
sub state_dec {
    my $self = shift;
    $self->state( $self->state - 1 );
}

=head2 $self->average_load

Returns server average load

=cut
sub average_load {
    my $self = shift;
    my $mtime = $self->model->time;
    return unless $mtime > 0;
    my $dtime = $mtime - $self->_last_state_update_time;
    my $cload = $self->_cummulative_load + $self->_state * $dtime;
    $cload/$mtime;
}

# TODO : histogram

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

