package Simulation::DiscreteEvent;

use Moose;
use Module::Load;
use Simulation::DiscreteEvent::Event;
use namespace::clean -except => ['meta'];

our $VERSION = '0.09';

=head1 NAME

Simulation::DiscreteEvent - module for discrete-event simulation

=head1 SYNOPSIS

    use Simulation::DiscreteEvent;

=head1 DESCRIPTION

This module implements library for discrete-event simulation. Currently it is
beta quality, I do not plan any backward incompatible changes in interface,
but everything may happen. Please see L<Simulation::DiscreteEvent::Cookbook>
for information about using this module.

=head1 SUBROUTINES/METHODS

=head2 new

Creates simulation object.

=cut
sub BUILD {
    my $self = shift;

    $self->_time(0);
}

=head2 $self->time

Returns current model time.

=cut

has time => ( reader => 'time', writer => '_time', isa => 'Num' );

has _servers => ( is => 'ro', isa => 'ArrayRef', default => sub { [] } );

has _events => ( is => 'ro', isa => 'ArrayRef', default => sub { [] } );

=head2 $self->schedule($time, $server, $event[, $message])

Schedule event at I<$time> for I<$server>. I<$event> is a string that
defines event type. I<$message> is a message that will be passed to I<$server>'s
event handler.

=cut
sub schedule {
    my ($self, $time, $server, $event_type, $message) = @_;
    die "Can't schedule event in the past" if $time < $self->time;
    my $event = Simulation::DiscreteEvent::Event->new(
        time    => $time,
        server  => $server,
        type    => $event_type,
        message => $message
    );
    my $i=0;
    for (@{$self->_events}) {
        last if $_->time > $time;
        $i++;
    }
    splice @{$self->_events}, $i, 0, $event;
    1;
}

=head2 $self->send($server, $event[, $message])

Schedule I<$event> for I<$server> to happen right now.

=cut
sub send {
    my $self = shift;
    $self->schedule($self->time, @_);
}

=head2 $self->add($server_class, %parameters)

Will create new object of class I<$server_class> and add it to model.
I<%parameters> are passed to the object constructor. Returns reference to the
created object.

=cut
sub add {
    my $self = shift;
    my $server_class = shift;
    {
        no strict 'refs';
        load $server_class unless @{"${server_class}::ISA"};
    }
    my $srv = $server_class->new( model => $self, @_ );
    push @{$self->_servers}, $srv;
    return $srv;
}

=head2 $self->run([$stop_time])

Start simulation. You should schedule at least one event before run simulation.
Simulation will be finished at I<$stop_time> if specified, or when there will
be no more events scheduled for execution.

=cut
sub run {
    my $self      = shift;
    my $stop_time = shift;
    my $counter;
    while ( my $event = shift @{ $self->_events } ) {
        if ( $stop_time && $stop_time < $event->time ) {
            unshift @{ $self->_events }, $event;
            $self->_time($stop_time);
            last;
        }
        $self->_time( $event->time );
        $event->handle;
        $counter++;
    }
    $counter;
}

=head2 $self->step

Handles one event from the events queue.

=cut
sub step {
    my $self  = shift;
    my $event = shift @{ $self->_events };
    return unless $event;
    $self->_time( $event->time );
    $event->handle;
    1;
}

1;

__END__

=head1 AUTHOR

Pavel Shaydo, C<< <zwon at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-simulation-discreteevent at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Simulation-DiscreteEvent>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Simulation::DiscreteEvent

Project's git repository can be accessed at

    http://github.com/trinitum/perl-Simulation-DiscreteEvent

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Simulation-DiscreteEvent>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Simulation-DiscreteEvent>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Simulation-DiscreteEvent>

=item * Search CPAN

L<http://search.cpan.org/dist/Simulation-DiscreteEvent/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Pavel Shaydo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

