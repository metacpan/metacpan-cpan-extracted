package SignalWire::Skills::Builtin::ClaudeSkills;
use strict;
use warnings;
use Moo;
extends 'SignalWire::Skills::SkillBase';

use SignalWire::Skills::SkillRegistry;
SignalWire::Skills::SkillRegistry->register_skill('claude_skills', __PACKAGE__);

has '+skill_name'        => (default => sub { 'claude_skills' });
has '+skill_description' => (default => sub { 'Load Claude SKILL.md files as agent tools' });
has '+supports_multiple_instances' => (default => sub { 1 });

sub setup { 1 }

sub register_tools {
    my ($self) = @_;
    my $prefix = $self->params->{tool_prefix} // 'claude_';
    # In the Perl port, we register a stub tool that represents the skill.
    # Full file-discovery would require YAML parsing (not available in minimal installs).
    $self->define_tool(
        name        => "${prefix}skill",
        description => "Claude skill tool (stub)",
        parameters  => {
            type       => 'object',
            properties => {
                arguments => { type => 'string', description => 'Arguments to pass' },
            },
            required => ['arguments'],
        },
        handler => sub {
            my ($args, $raw) = @_;
            require SignalWire::SWAIG::FunctionResult;
            return SignalWire::SWAIG::FunctionResult->new(
                response => "Claude skill invoked with: $args->{arguments}"
            );
        },
    );
}

sub get_hints {
    my ($self) = @_;
    return ['claude', 'skill'];
}

sub get_parameter_schema {
    return {
        %{ SignalWire::Skills::SkillBase->get_parameter_schema },
        skills_path => { type => 'string', required => 1 },
        tool_prefix => { type => 'string', default => 'claude_' },
    };
}

1;
