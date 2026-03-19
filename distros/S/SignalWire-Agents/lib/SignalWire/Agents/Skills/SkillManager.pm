package SignalWire::Agents::Skills::SkillManager;
# Copyright (c) 2025 SignalWire
# Licensed under the MIT License.

use strict;
use warnings;
use Moo;
use Carp qw(croak);

has agent         => (is => 'ro', required => 1, weak_ref => 1);
has loaded_skills => (is => 'rw', default => sub { {} });

sub load_skill {
    my ($self, $skill_name, $skill_class, $params) = @_;
    $params //= {};

    # Get class from registry if not provided
    if (!$skill_class) {
        require SignalWire::Agents::Skills::SkillRegistry;
        my $factory = SignalWire::Agents::Skills::SkillRegistry->get_factory($skill_name);
        unless ($factory) {
            return (0, "Skill '$skill_name' not found in registry");
        }
        $skill_class = $factory;
    }

    # Create instance
    my $instance = eval {
        $skill_class->new(
            agent  => $self->agent,
            params => { %$params },
        );
    };
    if ($@) {
        return (0, "Failed to create skill '$skill_name': $@");
    }

    my $instance_key = $instance->get_instance_key;

    # Check for duplicates
    if (exists $self->loaded_skills->{$instance_key}) {
        if (!$instance->supports_multiple_instances) {
            return (0, "Skill '$skill_name' already loaded and does not support multiple instances");
        }
    }

    # Validate env vars
    unless ($instance->validate_env_vars) {
        return (0, "Skill '$skill_name' missing required environment variables");
    }

    # Setup
    my $ok = eval { $instance->setup };
    if ($@ || !$ok) {
        my $err = $@ || 'setup() returned false';
        return (0, "Skill '$skill_name' setup failed: $err");
    }

    # Register tools
    eval { $instance->register_tools };
    if ($@) {
        return (0, "Skill '$skill_name' register_tools failed: $@");
    }

    # Merge hints
    my $hints = $instance->get_hints;
    if ($hints && @$hints) {
        $self->agent->add_hints(@$hints);
    }

    # Merge global data
    my $gdata = $instance->get_global_data;
    if ($gdata && %$gdata) {
        $self->agent->update_global_data($gdata);
    }

    # Add prompt sections
    my $sections = $instance->get_prompt_sections;
    if ($sections && @$sections) {
        for my $sec (@$sections) {
            $self->agent->prompt_add_section(
                $sec->{title},
                $sec->{body},
                ($sec->{bullets} ? (bullets => $sec->{bullets}) : ()),
            );
        }
    }

    $self->loaded_skills->{$instance_key} = $instance;
    return (1, '');
}

sub unload_skill {
    my ($self, $key) = @_;
    my $instance = delete $self->loaded_skills->{$key};
    if ($instance) {
        eval { $instance->cleanup };
        return 1;
    }
    return 0;
}

sub list_skills {
    my ($self) = @_;
    return [ keys %{ $self->loaded_skills } ];
}

sub has_skill {
    my ($self, $key) = @_;
    return exists $self->loaded_skills->{$key} ? 1 : 0;
}

1;
