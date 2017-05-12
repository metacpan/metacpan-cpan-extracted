package Simulation::DiscreteEvent::Generator;

use Moose;
our $VERSION = '0.09';
BEGIN { extends 'Simulation::DiscreteEvent::Server' }
use Carp;
use namespace::clean -except => ['meta'];

=head1 NAME

Simulation::DiscreteEvent::Generator - Event generator

=head1 SYNOPSIS

    my $gen = $model->add(
        'Simulation::DiscreteEvent::Generator',
        start_at   => 2,
        interval   => sub { 7 * rand },
        message    => sub { sprintf "Now: %d", shift->model->time },
        event_name => 'ping',
        limit      => 1000,
        dest       => $server,
    );

=head1 DESCRIPTION

This class is descendant of L<Simulation::DiscreteEvent::Server>, its purpose
is to add event generators to model.

=head1 PARAMETERS

Here's the list of object attributes:

=cut

=head2 start_at

This attribute may be passed only at the time of object construction. It
specifies the time of the first event. If you didn't specified this parameter
you should schedule the "next" event for the created object, or it won't
generate any events.

=cut
has start_at => (is => 'ro', isa => 'Num');

=head2 interval

This attribute is a reference to subroutine that returns time till the next
event should happen. Usually this subroutine generates some random values.
Reference to the object is passed to subroutine as the only argument. This
attribute is required.

=cut
has interval => (is => 'rw', isa => 'CodeRef', required => 1);

=head2 message

This optional attribute contains reference to a subroutine that generates
messages which should be passed to destination event handler along with
events.

=cut
has message  => (is => 'rw', isa => 'CodeRef' );

=head2 event_name

Attribute contains name of the generated events.

=cut
has event_name => (is => 'rw', isa => 'Str', required => 1);

=head2 limit

Number of events that should be generated. If attribute is not defined, generator will never stop while simulation is running.

=cut
has limit => (is => 'rw', isa => 'Int');

=head2 dest

Server that should receive and handle generated events.

=cut
has dest  => (is => 'rw', isa => 'Simulation::DiscreteEvent::Server');

sub BUILD {
    my $self = shift;
    if ( defined $self->start_at ) {
        $self->model->schedule( $self->start_at, $self, 'next' );
    }
}

sub _next :Event(next) {
    my $self = shift;
    my $limit = $self->limit;
    return if defined($limit) && $limit <= 0;
    confess "destination for generated events is not defined!" unless defined($self->dest);

    # send generated event to destination
    if ( $self->message ) {
        $self->model->send( $self->dest, $self->event_name, $self->message->($self) );
    }
    else {
        $self->model->send( $self->dest, $self->event_name );
    }
    if ( defined($limit) ) {
        return unless $self->limit( $limit - 1 ) > 0;
    }

    # schedule next event
    $self->model->schedule( 
        $self->model->time + $self->interval->($self), $self, 'next' );
}

no Moose;
__PACKAGE__->meta->make_immutable;
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

