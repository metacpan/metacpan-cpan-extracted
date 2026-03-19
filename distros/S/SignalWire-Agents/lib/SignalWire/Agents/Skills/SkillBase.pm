package SignalWire::Agents::Skills::SkillBase;
# Copyright (c) 2025 SignalWire
# Licensed under the MIT License.

use strict;
use warnings;
use Moo;
use Carp qw(croak);

# Required class-level constants (subclasses override via 'has' or '+')
has skill_name        => (is => 'ro', required => 1);
has skill_description => (is => 'ro', required => 1);
has skill_version     => (is => 'ro', default => sub { '1.0.0' });

has supports_multiple_instances => (is => 'ro', default => sub { 0 });
has required_packages           => (is => 'ro', default => sub { [] });
has required_env_vars           => (is => 'ro', default => sub { [] });

# The agent this skill is attached to
has agent  => (is => 'ro', required => 1, weak_ref => 1);
# Config params passed at registration
has params => (is => 'rw', default => sub { {} });

# Extra SWAIG fields to merge into tool definitions
has swaig_fields => (is => 'rw', default => sub { {} });

sub BUILD {
    my ($self) = @_;
    # Extract swaig_fields from params if present
    if (exists $self->params->{swaig_fields}) {
        $self->swaig_fields(delete $self->params->{swaig_fields});
    }
}

# --- Abstract interface (subclasses must override) ---

sub setup {
    my ($self) = @_;
    croak(ref($self) . " must implement setup()");
}

sub register_tools {
    my ($self) = @_;
    croak(ref($self) . " must implement register_tools()");
}

# --- Default implementations ---

sub define_tool {
    my ($self, %opts) = @_;
    # Merge swaig_fields into the tool definition
    my %merged = (%{ $self->swaig_fields }, %opts);
    return $self->agent->define_tool(%merged);
}

sub get_hints {
    return [];
}

sub get_global_data {
    return {};
}

sub get_prompt_sections {
    my ($self) = @_;
    return [] if $self->params->{skip_prompt};
    return $self->_get_prompt_sections;
}

sub _get_prompt_sections {
    return [];
}

sub cleanup {
    # no-op by default
}

sub validate_env_vars {
    my ($self) = @_;
    for my $var (@{ $self->required_env_vars }) {
        return 0 unless $ENV{$var};
    }
    return 1;
}

sub get_parameter_schema {
    return {
        swaig_fields => { type => 'object', description => 'Additional SWAIG fields' },
        skip_prompt  => { type => 'boolean', description => 'Skip injecting prompt sections', default => 0 },
        tool_name    => { type => 'string',  description => 'Override the default tool name' },
    };
}

sub get_instance_key {
    my ($self) = @_;
    my $base = $self->skill_name;
    if ($self->params->{tool_name}) {
        return $base . ':' . $self->params->{tool_name};
    }
    return $base;
}

1;
