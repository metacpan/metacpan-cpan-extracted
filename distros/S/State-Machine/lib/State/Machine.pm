# ABSTRACT: Simple State Machine Implementation
package State::Machine;

use Bubblegum::Class;
use Function::Parameters;
use State::Machine::Failure::Transition::Execution;
use State::Machine::Failure::Transition::Missing;
use State::Machine::Failure::Transition::Unknown;
use Try::Tiny;

use Bubblegum::Constraints -typesof;

our $VERSION = '0.07'; # VERSION

has 'state' => (
    is       => 'rw',
    isa      => typeof_object,
    required => 1
);

has 'topic' => (
    is       => 'ro',
    isa      => typeof_string,
    required => 1
);

method apply {
    my $state = $self->state;
    my $next  = $self->next;

    # cannot transition
    State::Machine::Failure::Transition::Missing->throw
        unless $next->isa_string;

    # find transition
    if (my $trans = $state->transitions->get($next)) {
        try {
            # attempt transition
            $self->state($trans->execute($state, @_));
        }
        catch {
            # transition execution failure
            State::Machine::Failure::Transition::Execution->throw(
                captured          => $_,
                transition_name   => $next,
                transition_object => $trans,
            );
        }
    }
    else {
        # transition unknown
        State::Machine::Failure::Transition::Unknown->throw(
            transition_name => $next
        );
    }

    return $self->state;
};

method next {
    my $state = $self->state;
    my $next  = shift // $state->next;

    if ($state && !$next) {
        # deduce transition unless defined
        if ($state->transitions->keys->count == 1) {
            $next = $state->transitions->keys->get(0);
        }
    }

    return $next;
}

method status {
    return $self->state->name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

State::Machine - Simple State Machine Implementation

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    use State::Machine;
    use State::Machine::State;
    use State::Machine::Transition;

    # light-switch circular-state example

    my $is_on  = State::Machine::State->new(name => 'is_on');
    my $is_off = State::Machine::State->new(name => 'is_off');

    my $turn_on  = State::Machine::Transition->new(
        name   => 'turn_on',
        result => $is_on
    );
    my $turn_off = State::Machine::Transition->new(
        name   => 'turn_off',
        result => $is_off
    );

    $is_on->add_transition($turn_off); # on -> turn off
    $is_off->add_transition($turn_on); # off -> turn on

    my $lightswitch = State::Machine->new(
        topic => 'typical light switch',
        state => $is_off
    );

    $lightswitch->apply('turn_on');
    $lightswitch->status; # is_on

=head1 DESCRIPTION

A finite-state machine (FSM) or finite-state automaton (plural: automata), or
simply a state machine, is an abstract machine that can be in one of a finite
number of states. The machine is in only one state at a time. It can change from
one state to another when initiated by a triggering event or condition; this is
called a transition. State::Machine is a system for creating state machines and
managing their transitions; It is also a great mechanism for enforcing and
tracking workflow, especially in distributed computing. This library is a
Moose-based implementation of the L<State::Machine> library.

State machines are useful for modeling systems with perform a predetermined
sequence of event and result in deterministic state. State::Machine, as you
might expect, allows for the definition of events, states, state transitions
and user defined actions that can be executed before or after transitions. All
features of the state machine itself can be configured via a DSL,
L<State::Machine::Simple>. B<Note: This is an early release available for
testing and feedback and as such is subject to change.>

=head1 ATTRIBUTES

=head2 state

    my $state = $machine->state;
    $state = $machine->state(State::Machine::State->new(...));

The current state of the state machine. The value should be a
L<State::Machine::State> object.

=head2 topic

    my $topic = $machine->topic;
    $topic = $machine->topic('Take over the world');

The topic or purpose of the state machine. The value can be any arbitrary
string describing intent.

=head1 METHODS

=head2 apply

    my $state = $machine->apply('transition_name');
    $state = $machine->apply; # apply known next transition

The apply method transitions the state machine from the current state into the
resulting state. If the apply method is called without a transition name, the
machine will transition into the next known state of the current state.

=head2 next

    my $transition_name = $machine->next;

The next method returns the name of the next known transition of the current
state if exists, otherwise it will return undefined.

=head2 status

    my $state_name = $machine->status;

The status method returns the name of the current state.

=encoding utf8

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
