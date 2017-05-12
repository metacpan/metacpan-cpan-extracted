package Simulation::DiscreteEvent::Sink;

use Moose;
our $VERSION = '0.09';
BEGIN { extends 'Simulation::DiscreteEvent::Server' }
with 'Simulation::DiscreteEvent::Recorder';
use namespace::clean -except => ['meta'];

=head1 NAME

Simulation::DiscreteEvent::Sink - collect information about customers that leaving system

=head1 SYNOPSIS

    $sink = $model->add(
        'Simulation::DiscreteEvent::Sink',
        allowed_events => [ qw(served rejected) ],
    );

=head1 DESCRIPTION

This class is descendant of L<Simulation::DiscreteEvent::Server> and
implements L<Simulation::DiscreteEvent::Recorder> role. Purpose of this class
is collecting statistics about customers leaving the system.

=head1 METHODS

This class doesn't implement its own methods, see
L<Simulation::DiscreteEvent::Recorder> documentation to get the list of
available methods.

=head1 ATTRIBUTES

Class has one attribute that may be passed to constructor.

=head2 allowed_events

Reference to an array with names of allowed events. If attribute is not defined,
all events are accepted.

=cut

has allowed_events => ( is => 'ro', isa => 'ArrayRef[Str]' );
has _allowed => ( is => 'rw', isa => 'HashRef' );

sub BUILD {
    my $self = shift;
    if ($self->allowed_events) {
        my $ref = {};
        for (@{$self->allowed_events}) {
            $ref->{$_} = 1;
        }
        $self->_allowed($ref);
    }
}

sub _dispatch {
    my $self = shift;
    my $event = shift;
    return \&_empty_handler unless defined $self->_allowed;
    return \&_empty_handler if $self->_allowed->{$event};
    confess "Event `$event' is not in the list of allowed events!";
}

sub _empty_handler { 1 }

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

