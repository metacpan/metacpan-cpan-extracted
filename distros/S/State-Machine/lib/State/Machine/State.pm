# ABSTRACT: State Machine State Class
package State::Machine::State;

use Bubblegum::Class;
use Function::Parameters;
use State::Machine::Failure::Transition::Unknown;
use State::Machine::Transition;
use Try::Tiny;

use Bubblegum::Constraints -typesof;

our $VERSION = '0.07'; # VERSION

has 'name' => (
    is       => 'ro',
    isa      => typeof_string,
    required => 1
);

has 'next' => (
    is       => 'rw',
    isa      => typeof_string,
    required => 0
);

has 'transitions' => (
    is      => 'ro',
    isa     => typeof_hashref,
    default => sub {{}}
);

method add_transition {
    my $trans = pop;
    my $name  = shift;

    if ($trans->isa('State::Machine::Transition')) {
        $name //= $trans->name;
        $self->transitions->set($name => $trans);
        return $trans;
    }

    # transition not found
    State::Machine::Failure::Transition::Unknown->throw(
        transition_name => $name,
    );
}

method remove_transition {
    my $name = shift;

    if ($self->transitions->get($name->asa_string)) {
        return $self->transitions->delete($name);
    }

    # transition not found
    State::Machine::Failure::Transition::Unknown->throw(
        transition_name => $name,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

State::Machine::State - State Machine State Class

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    use State::Machine::State;

    my $state = State::Machine::State->new(
        name => 'sleep',
        next => 'resume'
    );

=head1 DESCRIPTION

State::Machine::State represents a state and it's transitions.

=head1 ATTRIBUTES

=head2 name

    my $name = $state->name;
    $name = $state->name('inspired');

The name of the state. The value can be any scalar value.

=head2 next

    my $transition_name = $state->next;
    $transition_name = $state->next('create_art');

The name of the next transition. The value can be any scalar value. This value
is used in automating the transition from one state to the next.

=head2 transitions

    my $transitions = $state->transitions;

The transitions attribute contains the collection of transitions the state can
apply. The C<add_transition> and C<remove_transition> methods should be used to
configure state transitions.

=head1 METHODS

=head2 add_transition

    $trans = $state->add_transition(State::Machine::Transition->new(...));
    $state->add_transition(name => State::Machine::Transition->new(...));

The add_transition method registers a new transition in the transitions
collection. The method requires a L<State::Machine::Transition> object.

=head2 remove_transition

    $trans = $state->remove_transition('transition_name');

The remove_transition method removes a pre-defined transition from the
transitions collection. The method requires a transition name.

=encoding utf8

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
