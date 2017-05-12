package MooseX::Callbacks;

use Moose::Role;
use Try::Tiny;
use namespace::autoclean;

# \%event => [ \&cb1, \&cb2 ... ]
has '_callbacks' => (
    is => 'rw',
    isa => 'HashRef[ArrayRef[CodeRef]]',
    default => sub { {} },
    lazy => 1,
    
    traits  => ['Hash'],
    handles => {
        set_callbacks   => 'set',
        get_callbacks   => 'get',
        clear_callbacks => 'delete',
        has_callbacks   => 'exists',
    },
);

=head1 NAME

MooseX::Callbacks - Add ability to register and call callbacks with a role.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  package Foo;
  use Moose;
  with 'MooseX::Callbacks';

  ...

  my $foo = Foo->new;
  $foo->register_callbacks(ding => \&dong);
  $foo->dispatch('ding', $arg1, $arg2...);

=head1 ATTRIBUTES

=head2 _callbacks

Hashref of arrayrefs of callbacks. Delegates via native traits C<set_callbacks>, C<get_callbacks>, C<clear_callbacks>, C<has_callbacks>

=head1 METHODS

=head2 register_callback($event => \&callback)

Same as C<register_callbacks>

=head2 register_callbacks(event1 => \&callback[, event2 => \&callback2 ...])

Registers callbacks for given events. Should be coderefs.

=cut

*register_callback = \&register_callbacks;
sub register_callbacks {
    my ($self, %cbs) = @_;
    
    foreach my $k (keys %cbs) {
        $self->_callbacks->{$k} ||= [];

        # don't add the same callback twice
        next if grep { $_ == $cbs{$k} } @{ $self->get_callbacks($k) };
        
        push @{ $self->get_callbacks($k) }, $cbs{$k};
    }
}

=head2 dispatch($event, @args)

Calls callbacks for $event with @args as parameters.

=cut


sub dispatch {
    my ($self, $event, @extra) = @_;

    my $cbs = $self->get_callbacks($event);

    if (! $cbs || ! @$cbs) {
        #warn("unhandled callback on $self: $event");
        return 0;
    }

    # call each registered callback
    foreach my $cb (@$cbs) {
        try {
            $cb->(@extra);
        } catch {
            my $err = shift;
            warn "Error calling callback for '$event': $err";
        };
    }

    return 1;
}

=head1 TODO

Ability to unregister callbacks.

=head1 AUTHOR

Mischa Spiegelmock, C<< <revmischa at cpan.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::Callbacks

=head1 ACKNOWLEDGEMENTS

Nobody.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Mischa Spiegelmock.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
