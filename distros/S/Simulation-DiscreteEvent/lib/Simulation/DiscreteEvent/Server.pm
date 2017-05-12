package Simulation::DiscreteEvent::Server;

use Moose;
our $VERSION = '0.09';
BEGIN { extends 'MooseX::MethodAttributes::Inheritable' }
use namespace::clean -except => ['meta'];

=head1 NAME

Simulation::DiscreteEvent::Server - Moose class for implementing servers

=head1 SYNOPSIS

    package MyServer;
    use Moose;
    BEGIN {
        extends 'Simulation::DiscreteEvent::Server';
    }
    sub start_handler : Event(start) {
        # handle start event here
    }
    sub stop : Event {
        # handle stop event here
    }
    no Moose;
    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

This is a base class for implementing servers for L<Simulation::DiscreteEvent>
models. Please see description and examples of using this module in
L<Simulation::DiscreteEvent::Cookbook>.

=head1 METHODS

=cut

has model => ( is => 'ro', isa => 'Simulation::DiscreteEvent', weak_ref => 1 );

=head2 $self->name([$name])

Allows you to get/set the name of the server

=cut
has name => ( is => 'rw', isa => 'Str' );

=head2 $self->handle($event, @args)

Invoke handler for I<$event> and pass to it I<@args> as arguments.

=cut
sub handle {
    my $self = shift;
    my $event = shift;
    my $handler = $self->_dispatch($event);
    die "Unknown event type `$event'" unless $handler;
    $handler->($self, @_);
}

my $_dispatch_table = {};

# get method that handles specified event
sub _dispatch {
    my $self = shift;
    my $event = shift;
    my $class = ref $self;
    unless (defined $_dispatch_table->{$class}) {
        _build_dispatch_table($class);
    }
    $_dispatch_table->{$class}{$event};
}

# build dispatch table for the class
sub _build_dispatch_table {
    my $class = shift;
    $_dispatch_table->{$class} = {};
    for my $method ( $class->meta->get_all_methods_with_attributes ) {
        my ($handles) = 
            map { /^Event(?:\((.+)\))?$/; $1 || $method->name }
            grep { /^Event(\(.*\))?$/ }
            @{ $method->attributes };
        next unless $handles;
        $_dispatch_table->{$class}{$handles} = $class->can( $method->name );
    }
    return;
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

