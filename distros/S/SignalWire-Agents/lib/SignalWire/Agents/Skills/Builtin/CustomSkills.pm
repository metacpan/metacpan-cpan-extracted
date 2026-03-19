package SignalWire::Agents::Skills::Builtin::CustomSkills;
use strict;
use warnings;
use Moo;
extends 'SignalWire::Agents::Skills::SkillBase';

use SignalWire::Agents::Skills::SkillRegistry;
SignalWire::Agents::Skills::SkillRegistry->register_skill('custom_skills', __PACKAGE__);

has '+skill_name'        => (default => sub { 'custom_skills' });
has '+skill_description' => (default => sub { 'Register user-defined custom tools' });
has '+supports_multiple_instances' => (default => sub { 1 });

sub setup { 1 }

sub register_tools {
    my ($self) = @_;
    my $tools = $self->params->{tools} // [];

    for my $tool_def (@$tools) {
        next unless ref $tool_def eq 'HASH';
        if (exists $tool_def->{function}) {
            $self->agent->register_swaig_function($tool_def);
        } elsif (exists $tool_def->{name}) {
            $self->agent->define_tool(%$tool_def);
        }
    }
}

sub get_parameter_schema {
    return {
        %{ SignalWire::Agents::Skills::SkillBase->get_parameter_schema },
        tools => { type => 'array', description => 'Array of tool definition objects' },
    };
}

1;
