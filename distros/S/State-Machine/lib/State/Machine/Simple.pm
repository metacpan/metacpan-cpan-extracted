# ABSTRACT: Simple State Machine DSL
package State::Machine::Simple;

use Bubblegum;
use State::Machine;
use State::Machine::Failure::Simple;
use State::Machine::State;
use State::Machine::Transition;

use parent 'Exporter::Tiny';

our $VERSION = '0.07'; # VERSION

our %CONFIGS;
our @EXPORT_OK   = qw(at_state in_state topic);
our %EXPORT_TAGS = (dsl => \@EXPORT_OK);

sub import {
    my $class  = shift;
    my $target = caller;

    no strict 'refs';
    no warnings 'redefine';
    push @{"${target}::ISA"}, 'State::Machine';
    my $constructor = $target->can('new');

    *{"${target}::new"} = sub { $constructor->(BUILDMACHINE(@_)) };
    $class->next::method({into => $target}, @_);
}

sub topic {
    return _stash_config(
        topic => [@_]
    );
}

sub at_state {
    return _stash_config(
        at_state => [@_]
    );
}

sub in_state {
    return _stash_config(
        in_state => [@_]
    );
}

sub BUILDMACHINE {
    my ($class, @args) = @_;
    my $args   = $args[0]->isa_hashref ? $args[0] : {@args};
    my $config = $CONFIGS{$class};

    my $init  = $config->get('at_state')->get(0)->first;
    my $root  = State::Machine::State->new(name => $init);
    my $topic = $config->get('topic')->get(0)->first;
    my $nodes = [$config->get('at_state')->list, $config->get('in_state')->list];

    my %register = ($init => $root);

    # states
    for my $node ($nodes->list) {
        my ($name, %args) = @{$node};
        my $state = $register{$name} //= State::Machine::State->new(
            name => $name
        );
    }

    # transitions
    for my $node ($nodes->list) {
        my ($name, %args) = @{$node};
        my $state = $register{$name};

        # automate next transition
        $state->next($args{next}) if $args{next};

        while (my($key, $val) = each %{$args{when}}) {
            my $result = $register{$val}
                or State::Machine::Failure::Simple->throw(
                    config  => $node,
                    message => sprintf
                        "Transition ($key) cannot result in the state ".
                        "($val); The state was not defined.",
                );

            my $trans  = State::Machine::Transition->new(
                name   => $key,
                result => $result
            );

            for my $hook (qw(before during after)) {
                my $routine = $class->can("_${hook}_${key}") or next;
                $trans->hook($hook => $routine);
            }

            # bind transition to state
            $state->add_transition($trans);
        }
    }

    $args->{topic} = $topic;
    $args->{state} = $root;

    return $class, $args;
}

sub _stash_config {
    my $type   = shift;
    my $target = caller(1);
    push @{$CONFIGS{$target}{$type}}, shift;
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

State::Machine::Simple - Simple State Machine DSL

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    package LightSwitch;

    use State::Machine::Simple -dsl;

    # light-switch circular-state example

    topic 'typical light switch';

    in_state 'is_off' => ( when => { turn_on => 'is_on' } );
    at_state 'is_on'  => ( when => { turn_off => 'is_off' } );

    sub _before_turn_on {
        my ($trans, $state, @args) = @_;
        # do something; maybe plug it in
    }

    sub _during_turn_on {
        my ($trans, $state, @args) = @_;
        # do something; maybe turn the knob or pull the lever
    }

    sub _after_turn_on {
        my ($trans, $state, @args) = @_;
        # do something else; maybe change adjust the positioning
    }

    package main;

    my $lightswitch = LightSwitch->new;

    $lightswitch->apply('turn_off');
    $lightswitch->status; # is_off

=head1 DESCRIPTION

State::Machine::Simple is a micro-framework for defining simple state machines
using L<State::Machine>. L<State::Machine> allows you to define a process, model
interactions, and enforce the integrity of those interactions. State machines
can also be used as a system for processing and reasoning about long-running
asynchronous transactions. As an example of the functionality provided by this
DSL, the follow is a demonstration of modeling a fictitious call-center process
modeled using State::Machine::Simple. This library is a Moose-based
implementation of the L<State::Machine> library.

    package CallCenter::Workflow::TelephoneCall;

    use State::Machine::Simple -dsl;

    topic 'support telephone call';

    # initial state
    at_state ringing => (
        # next transition
        next => 'connect',

        # applicable transitions
        when => {
            hangup  => 'disconnected', # transition -> resulting state
            connect => 'connected',    # transition -> resulting state
        }
    );

    in_state connected => (
        next => 'request_dept',
        when => {
            hangup       => 'disconnected',
            request_dept => 'transferred',
        }
    );

    in_state transferred => (
        next => 'answer',
        when => {
            hangup    => 'disconnected',
            voicemail => 'disconnected',
            answer    => 'answered',
        }
    );

    in_state answered => (
        next => 'hangup',
        when => {
            hangup => 'disconnected'
        }
    );

    in_state 'disconnected'; # end-state (cannot transition from)

=head1 EXPORTS

=head2 -dsl

The dsl export group exports all functions instrumental in modeling a simple
state machine. The following is a list of functions exported by this group:

=over 4

=item *

at_state

=item *

in_state

=item *

topic

=back

=head1 FUNCTIONS

=head2 at_state

    at_state name => (%attributes);

    at_state answered => (when => { hangup => 'disconnected' });
    # using the telephone example provided in the description, this state
    # definition can be read as ... a $state (answered) $topic (support
    # telephone call) $transition (hangup) and is now $state (disconnected)

The at_state function is analogous to the in_state function and additionally
denotes that it's state definition is the root state (starting point).

=head2 in_state

    in_state name => (%attributes);

    in_state connected => (when => { request_dept => 'transferred' });
    # using the telephone example provided in the description, this state
    # definition can be read as ... a $state (connected) $topic (support
    # telephone call) $transition (request_dept) and is now $state (transferred)

The in_state function defines a state and optionally it's transitions. The
in_state function requires a state name as it's first argument, and optionally
a list of attributes that will be used to configure other state behavior. The
value of the C<when> attribute should be a hashref whose keys are names of
transitions, and whose values are names of states.

=head2 topic

    topic 'process credit card';

The topic function takes an arbitrary string which describes the purpose or
intent of the state machine.

=encoding utf8

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
