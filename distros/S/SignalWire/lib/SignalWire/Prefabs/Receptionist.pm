package SignalWire::Prefabs::Receptionist;
# Copyright (c) 2025 SignalWire
# Licensed under the MIT License.

use strict;
use warnings;
use Moo;
use JSON qw(encode_json);
extends 'SignalWire::Agent::AgentBase';

has departments => (is => 'ro', default => sub { [] });
has greeting    => (is => 'ro', default => sub { 'Thank you for calling. How can I help you today?' });
has voice       => (is => 'ro', default => sub { 'rime.spore' });

sub BUILD {
    my ($self, $args) = @_;

    $self->name('receptionist')  if $self->name eq 'agent';
    $self->route('/receptionist') if $self->route eq '/';
    $self->use_pom(1);

    my $departments = $self->departments;

    $self->set_global_data({
        departments => $departments,
        caller_info => {},
    });

    # Build department list for prompt
    my @dept_bullets;
    for my $dept (@$departments) {
        push @dept_bullets, "$dept->{name}: $dept->{description}";
    }

    $self->prompt_add_section(
        'Receptionist Role',
        $self->greeting,
        bullets => [
            'Greet the caller warmly',
            'Determine which department they need',
            'Transfer them to the correct department',
            @dept_bullets,
        ],
    );

    # Register transfer tool
    $self->define_tool(
        name        => 'transfer_to_department',
        description => 'Transfer the caller to the specified department',
        parameters  => {
            type       => 'object',
            properties => {
                department => { type => 'string', description => 'Department name to transfer to' },
            },
            required => ['department'],
        },
        handler => sub {
            my ($a, $raw) = @_;
            require SignalWire::SWAIG::FunctionResult;
            my $dept_name = $a->{department} // '';
            for my $dept (@$departments) {
                if (lc($dept->{name}) eq lc($dept_name)) {
                    my $result = SignalWire::SWAIG::FunctionResult->new(
                        response => "Transferring to $dept_name",
                    );
                    return $result;
                }
            }
            return SignalWire::SWAIG::FunctionResult->new(
                response => "Department '$dept_name' not found",
            );
        },
    );
}

1;
