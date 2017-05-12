# ABSTRACT: State Machine State Transition Class
package State::Machine::Transition;

use Bubblegum::Class;
use Function::Parameters;
use State::Machine::Failure::Transition::Hook;
use State::Machine::State;
use Try::Tiny;

use Bubblegum::Constraints -typesof;

our $VERSION = '0.07'; # VERSION

has 'name' => (
    is       => 'ro',
    isa      => typeof_string,
    required => 1
);

has 'result' => (
    is       => 'rw',
    isa      => typeof_object,
    required => 1
);

has 'hooks' => (
    is      => 'ro',
    isa     => typeof_hashref,
    default => sub {{ before => [], during => [], after => [] }}
);

has 'executable' => (
    is      => 'rw',
    isa     => typeof_integer,
    default => 1
);

has 'terminated' => (
    is      => 'rw',
    isa     => typeof_integer,
    default => 0
);

method execute {
    return if !$self->executable;

    my @schedules = (
        $self->hooks->get('before'),
        $self->hooks->get('during'),
        $self->hooks->get('after'),
    );

    for my $schedule (@schedules) {
        if ($schedule->isa_arrayref) {
            for my $task ($schedule->list) {
                next if !$task->isa_coderef;
                $task->call($self, @_);
            }
        }
    }

    return $self->result;
}

method hook {
    my $name = shift;
    my $code = shift;

    $name->asa_string;
    $code->asa_coderef;

    my $list = $self->hooks->get($name);

    unless ($list->isa_arrayref) {
        # transition hooking failure
        State::Machine::Failure::Transition::Hook->throw(
            hook_name         => $name,
            transition_name   => $self->name,
            transition_object => $self,
        );
    }

    $list->push($code);
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

State::Machine::Transition - State Machine State Transition Class

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    use State::Machine::Transition;

    my $trans = State::Machine::Transition->new(
        name   => 'resume',
        result => State::Machine::State->new(name => 'awake')
    );

    $trans->hook(during => sub {
        my ($trans, $state, @args) = @_;
        # do something during resume
    });

=head1 DESCRIPTION

State::Machine::Transition represents a state transition and it's resulting
state.

=head1 ATTRIBUTES

=head2 executable

    my $executable = $trans->executable;
    $trans->executable(1);

The executable flag determines whether a transition can be execute.

=head2 hooks

    my $hooks = $trans->hooks;

The hooks attribute contains the collection of triggers and events to be fired
when the transition is executed. The C<hook> method should be used to configure
any hooks into the transition processing.

=head2 name

    my $name = $trans->name;
    $name = $trans->name('suicide');

The name of the transition. The value can be any scalar value.

=head2 result

    my $state = $trans->result;
    $state = $trans->result(State::Machine::State->new(...));

The result represents the resulting state of a transition. The value must be a
L<State::Machine::State> object.

=head1 METHODS

=head2 hook

    $trans = $trans->hook(during => sub {...});
    $trans->hook(before => sub {...});
    $trans->hook(after => sub {...});

The hook method registers a new hook in the append-only hooks collection to be
fired when the transition is executed. The method requires an event name,
either C<before>, C<during>, or C<after>, and a code reference.

=encoding utf8

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
